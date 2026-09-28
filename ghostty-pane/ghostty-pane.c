// ghostty-pane: the shell of Ghostty's panes, with Neovim over the pane on C-y in place of tmux's copy mode
// (config/ghostty/config.ghostty)
//
//   ghostty-pane <shell> [<arg>...]
//
// It runs the shell in a terminal of its own, and passes everything through. C-y has Ghostty send F20, the path of a
// file it wrote the pane's screen and history to, and a return: Neovim opens the file over the pane, in a terminal of
// its own too, to scroll, search and yank with the keyboard. What runs in the pane keeps running: its output is held
// back until Neovim quits, and written then, after what the program had set that Neovim resets (bracketed paste, the
// keypad, the mouse, the cursor, the title...). A program on the alternate screen is made to redraw it. C-y in
// Neovim scrolls up, as in copy mode.
//
// Neovim runs through the user's shell ($SHELL -c), which puts it on PATH: Ghostty starts this with launchd's PATH.
// Started as a login shell, with argv[0] starting with - as Ghostty's `exec -l` does, it starts the shell as one.

#define _DEFAULT_SOURCE
#define _DARWIN_C_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#ifdef __APPLE__
#include <util.h>
#else
#include <pty.h>
#endif

// What C-y sends (config/ghostty/config.ghostty): F20, then the path, then a return
#define TRIGGER "\x1b[34~"
#define TRIGGER_LEN (sizeof TRIGGER - 1)

// Neovim on the file: read-only, with no swap file, and no modelines, which programs could print. At its end, on the
// last line with text, where the cursor was: the screen's empty lines come after.
#define VIEWER "exec nvim -n -M --cmd 'set nomodeline' + -c \"call search('\\\\S', 'bcW')\" -- \"$1\""

// How long to wait for the rest of F20 that a read cut off, and for the path after it
#define PREFIX_WAIT 0.05
#define PATH_WAIT 3.0

// How long to wait for the rest of a program's output once it has exited, and for the end of the escape sequence it
// was writing when Neovim starts
#define DRAIN_WAIT 0.1
#define SETTLE_WAIT 0.5

// The most output to hold while Neovim runs, and input to queue: then the program has to wait
#define HOLD_MAX (64 << 20)
#define INPUT_MAX (1 << 20)

//  Buffers
//-----------------------------------------------
struct buf {
  char *data;
  size_t len, cap;
};

static void buf_add(struct buf *b, const void *data, size_t len) {
  if (b->len + len > b->cap) {
    size_t cap = b->cap ? b->cap : 4096;
    while (cap < b->len + len) cap *= 2;
    char *p = realloc(b->data, cap);
    if (!p) abort();
    b->data = p;
    b->cap = cap;
  }
  memcpy(b->data + b->len, data, len);
  b->len += len;
}

static void buf_str(struct buf *b, const char *s) {
  buf_add(b, s, strlen(s));
}

static void buf_int(struct buf *b, int n) {
  char s[16];
  snprintf(s, sizeof s, "%d", n);
  buf_str(b, s);
}

static void buf_drop(struct buf *b, size_t len) {
  memmove(b->data, b->data + len, b->len - len);
  b->len -= len;
}

//  Terminals
//-----------------------------------------------
static struct termios tty_saved;
static int signal_pipe[2];

// The shell, and Neovim while it runs: their process and their terminal's end
static pid_t shell_pid, viewer_pid;
static int shell_fd = -1, viewer_fd = -1;
static bool shell_exited;
static int shell_status;

// Input waiting for them to read it
static struct buf shell_input, viewer_input;

static double now(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return ts.tv_sec + ts.tv_nsec / 1e9;
}

static struct timeval timeval_of(double seconds) {
  if (seconds < 0) seconds = 0;
  return (struct timeval){(time_t)seconds, (suseconds_t)((seconds - (time_t)seconds) * 1e6)};
}

// Waits for the file descriptor to be readable or writable, until the time given (a now()), or forever if 0
static void wait_fd(int fd, bool writing, double until) {
  fd_set set;
  FD_ZERO(&set);
  FD_SET(fd, &set);
  struct timeval tv = timeval_of(until - now());
  select(fd + 1, writing ? NULL : &set, writing ? &set : NULL, NULL, until ? &tv : NULL);
}

static void quit(int status) {
  tcsetattr(STDIN_FILENO, TCSANOW, &tty_saved);
  exit(status);
}

// Writes to the terminal, whatever it takes
static void term_write(const void *data, size_t len) {
  const char *p = data;
  while (len > 0) {
    ssize_t n = write(STDOUT_FILENO, p, len);
    if (n > 0) {
      p += n;
      len -= n;
    } else if (n < 0 && errno == EAGAIN) {
      wait_fd(STDOUT_FILENO, true, 0);
    } else if (n < 0 && errno != EINTR) {
      quit(1); // the terminal is gone
    }
  }
}

// A terminal of its own for a program, of the size of this one. Not left open in the programs started later.
static pid_t fork_terminal(int *fd) {
  struct winsize ws = {0};
  ioctl(STDIN_FILENO, TIOCGWINSZ, &ws);
  pid_t pid = forkpty(fd, NULL, &tty_saved, &ws);
  if (pid == 0) {
    // As the program would have them, with no handler, nothing ignored and nothing blocked
    for (int sig = 1; sig < NSIG; sig++) signal(sig, SIG_DFL);
    sigset_t none;
    sigemptyset(&none);
    sigprocmask(SIG_SETMASK, &none, NULL);
  } else if (pid > 0) {
    fcntl(*fd, F_SETFD, FD_CLOEXEC);
    fcntl(*fd, F_SETFL, fcntl(*fd, F_GETFL) | O_NONBLOCK);
  }
  return pid;
}

static void resize(void) {
  struct winsize ws;
  if (ioctl(STDIN_FILENO, TIOCGWINSZ, &ws) != 0) return;
  if (shell_fd >= 0) ioctl(shell_fd, TIOCSWINSZ, &ws);
  if (viewer_fd >= 0) ioctl(viewer_fd, TIOCSWINSZ, &ws);
}

//  What the shell's programs set
//-----------------------------------------------
// Their output is parsed as the terminal parses it, to know what to set again after Neovim, and where an escape
// sequence or a character ends: Neovim's output mustn't land in the middle of one.

// The DEC private modes to set again, on and off alike. Not those that move the cursor or clear the screen (3, 6),
// nor synchronized output (2026), which would keep the screen from updating. The mouse's are below.
static const int dec_modes[] = {1, 5, 7, 12, 25, 45, 1004, 1007, 1036, 2004, 2027, 2031, 2048};
#define DEC_MODES (sizeof dec_modes / sizeof dec_modes[0])

enum parser_state { GROUND, ESCAPE, ESCAPE_INTERMEDIATE, CSI, CSI_IGNORE, OSC, STRING };

static struct {
  enum parser_state state;
  int utf8_left; // bytes of a UTF-8 character still to come

  // The escape sequence being parsed, to write it again if Neovim cuts it off
  char seq[4096];
  size_t seq_len;
  bool seq_long;

  // A CSI sequence's private marker (? > < =), intermediate byte (e.g. DECSCUSR's space) and parameters
  char marker, intermediate;
  int params[16];
  int param_count;

  // An OSC sequence's text
  char osc[1024];
  size_t osc_len;

  // What was set, -1 while nothing was
  signed char dec_mode[DEC_MODES];
  int alt_screen;   // the mode that switched to the alternate screen (47, 1047, 1049), 0 for none
  int mouse_events; // 9, 1000, 1002 or 1003, 0 when off: Ghostty turns any of them off with any
  int mouse_format; // 1005, 1006, 1015 or 1016, 0 for the default: likewise
  int keypad;       // application keypad (DECKPAM, DECNKM): 1, else 0
  int cursor_style; // DECSCUSR
  int top, bottom;  // scrolling region, 0 for the screen's edges
  int title_osc;    // 0 or 2
  char title[1024];
} term;

// Back to the terminal's defaults, as after RIS
static void forget(void) {
  memset(term.dec_mode, -1, sizeof term.dec_mode);
  term.alt_screen = 0;
  term.mouse_events = term.mouse_format = term.keypad = term.cursor_style = -1;
  term.top = term.bottom = 0;
}

static void set_mode(int mode, bool on) {
  switch (mode) {
  case 47:
  case 1047:
  case 1049:
    term.alt_screen = on ? mode : 0;
    return;
  case 9:
  case 1000:
  case 1002:
  case 1003:
    term.mouse_events = on ? mode : 0;
    return;
  case 1005:
  case 1006:
  case 1015:
  case 1016:
    term.mouse_format = on ? mode : 0;
    return;
  case 66:
    term.keypad = on;
    return;
  }
  for (size_t i = 0; i < DEC_MODES; i++) {
    if (dec_modes[i] == mode) term.dec_mode[i] = on;
  }
}

static void esc_dispatch(unsigned char final) {
  switch (final) {
  case '=': // DECKPAM
    term.keypad = 1;
    break;
  case '>': // DECKPNM
    term.keypad = 0;
    break;
  case 'c': // RIS
    forget();
    break;
  }
}

static void csi_dispatch(unsigned char final) {
  if ((final == 'h' || final == 'l') && term.marker == '?' && !term.intermediate) {
    for (int i = 0; i < term.param_count; i++) set_mode(term.params[i], final == 'h');
  } else if (final == 'q' && term.intermediate == ' ' && !term.marker) {
    term.cursor_style = term.param_count ? term.params[0] : 0;
  } else if (final == 'r' && !term.marker && !term.intermediate) {
    term.top = term.param_count > 0 ? term.params[0] : 0;
    term.bottom = term.param_count > 1 ? term.params[1] : 0;
  } else if (final == 'p' && term.intermediate == '!' && !term.marker) {
    forget(); // DECSTR, a soft reset
  }
}

static void osc_dispatch(void) {
  // A title: 2, or 0 with the icon's
  if (term.osc_len >= 2 && (term.osc[0] == '0' || term.osc[0] == '2') && term.osc[1] == ';') {
    size_t len = term.osc_len - 2 < sizeof term.title - 1 ? term.osc_len - 2 : sizeof term.title - 1;
    memcpy(term.title, term.osc + 2, len);
    term.title[len] = '\0';
    term.title_osc = term.osc[0] - '0';
  }
}

static void seq_add(unsigned char c) {
  if (term.seq_len < sizeof term.seq) {
    term.seq[term.seq_len++] = c;
  } else {
    term.seq_long = true;
  }
}

static void track(unsigned char c) {
  // CAN and SUB cancel a sequence, and ESC starts one, ending an OSC or a string as ST's first byte
  if (c == 0x18 || c == 0x1a) {
    term.state = GROUND;
    term.utf8_left = 0;
    return;
  }
  if (c == 0x1b) {
    if (term.state == OSC) osc_dispatch();
    term.state = ESCAPE;
    term.utf8_left = 0;
    term.seq_len = 0;
    term.seq_long = false;
    seq_add(c);
    return;
  }

  switch (term.state) {
  case GROUND:
    if (term.utf8_left > 0 && (c & 0xc0) == 0x80) {
      term.utf8_left--;
    } else {
      term.utf8_left = c >= 0xf0 ? 3 : c >= 0xe0 ? 2 : c >= 0xc0 ? 1 : 0;
    }
    return;

  case ESCAPE:
    seq_add(c);
    if (c == '[') {
      term.state = CSI;
      term.marker = term.intermediate = 0;
      term.param_count = 0;
    } else if (c == ']') {
      term.state = OSC;
      term.osc_len = 0;
    } else if (c == 'P' || c == 'X' || c == '^' || c == '_') {
      term.state = STRING; // DCS, SOS, PM, APC: until ST
    } else if (c >= 0x20 && c <= 0x2f) {
      term.state = ESCAPE_INTERMEDIATE;
    } else if (c >= 0x30 && c <= 0x7e) {
      esc_dispatch(c);
      term.state = GROUND;
    }
    return; // C0 controls run in the middle of a sequence

  case ESCAPE_INTERMEDIATE:
    seq_add(c);
    if (c >= 0x30 && c <= 0x7e) term.state = GROUND; // e.g. a character set, ESC ( B
    return;

  case CSI:
    seq_add(c);
    if (c >= '0' && c <= '9') {
      if (term.param_count == 0) term.params[term.param_count++] = 0;
      int *param = &term.params[term.param_count - 1];
      if (*param < 100000) *param = *param * 10 + (c - '0');
    } else if (c == ';' || c == ':') {
      if (term.param_count == 0) term.params[term.param_count++] = 0;
      if (term.param_count < (int)(sizeof term.params / sizeof term.params[0])) {
        term.params[term.param_count++] = 0;
      } else {
        term.state = CSI_IGNORE;
      }
    } else if (c >= 0x3c && c <= 0x3f) {
      if (term.seq_len == 3) {
        term.marker = c;
      } else {
        term.state = CSI_IGNORE;
      }
    } else if (c >= 0x20 && c <= 0x2f) {
      term.intermediate = c;
    } else if (c >= 0x40 && c <= 0x7e) {
      csi_dispatch(c);
      term.state = GROUND;
    }
    return;

  case CSI_IGNORE:
    seq_add(c);
    if (c >= 0x40 && c <= 0x7e) term.state = GROUND;
    return;

  case OSC:
    seq_add(c);
    if (c == 0x07) {
      osc_dispatch();
      term.state = GROUND;
    } else if (term.osc_len < sizeof term.osc) {
      term.osc[term.osc_len++] = c;
    }
    return;

  case STRING:
    seq_add(c);
    return;
  }
}

// Sets again what the programs had set, and Neovim reset, or back to the terminal's defaults
static void restore(void) {
  struct buf b = {0};
  if (term.alt_screen) {
    buf_str(&b, "\x1b[?");
    buf_int(&b, term.alt_screen);
    buf_str(&b, "h");
  }
  // Within DECSC and DECRC, as it moves the cursor
  if (term.top || term.bottom) {
    buf_str(&b, "\x1b" "7\x1b[");
    if (term.top) buf_int(&b, term.top);
    if (term.bottom) {
      buf_str(&b, ";");
      buf_int(&b, term.bottom);
    }
    buf_str(&b, "r\x1b" "8");
  }
  for (size_t i = 0; i < DEC_MODES; i++) {
    if (term.dec_mode[i] < 0) continue;
    buf_str(&b, "\x1b[?");
    buf_int(&b, dec_modes[i]);
    buf_str(&b, term.dec_mode[i] ? "h" : "l");
  }
  if (term.mouse_events > 0) {
    buf_str(&b, "\x1b[?");
    buf_int(&b, term.mouse_events);
    buf_str(&b, "h");
  } else if (term.mouse_events == 0) {
    buf_str(&b, "\x1b[?1000l");
  }
  if (term.mouse_format > 0) {
    buf_str(&b, "\x1b[?");
    buf_int(&b, term.mouse_format);
    buf_str(&b, "h");
  } else if (term.mouse_format == 0) {
    buf_str(&b, "\x1b[?1006l");
  }
  if (term.keypad >= 0) buf_str(&b, term.keypad ? "\x1b=" : "\x1b>");
  // Neovim leaves its own
  buf_str(&b, "\x1b[");
  buf_int(&b, term.cursor_style >= 0 ? term.cursor_style : 0);
  buf_str(&b, " q");
  if (term.title_osc >= 0) {
    buf_str(&b, "\x1b]");
    buf_int(&b, term.title_osc);
    buf_str(&b, ";");
    buf_str(&b, term.title);
    buf_str(&b, "\x07");
  }
  term_write(b.data, b.len);
  free(b.data);
}

//  Output
//-----------------------------------------------
// The shell's output while Neovim runs, after the escape sequence it cut off
static struct buf held, held_start;

static void shell_output(const char *data, size_t len) {
  if (viewer_pid) {
    buf_add(&held, data, len);
    return;
  }
  term_write(data, len);
  for (size_t i = 0; i < len; i++) track((unsigned char)data[i]);
}

// Reads what a program wrote to its terminal: false once no program has it open
static bool read_from(int fd) {
  char data[65536];
  ssize_t n = read(fd, data, sizeof data);
  if (n > 0) {
    if (fd == shell_fd) {
      shell_output(data, n);
    } else {
      term_write(data, n);
    }
    return true;
  }
  return n < 0 && (errno == EINTR || errno == EAGAIN); // else EIO, or the end
}

// Reads the rest of what a program wrote before exiting: until no program has its terminal open, or, as programs it
// started may keep it, until a while
static void drain(int fd) {
  double until = now() + DRAIN_WAIT;
  while (fd >= 0 && now() < until) {
    wait_fd(fd, false, until);
    if (!read_from(fd)) return;
  }
}

//  Neovim
//-----------------------------------------------
// Where Ghostty writes the screen: in a directory of its own, in the temporary directory
static char tmp_dir[PATH_MAX];
static char viewer_file[PATH_MAX];

static bool screen_file(const char *path) {
  struct stat st;
  if (path[0] != '/' || lstat(path, &st) != 0 || !S_ISREG(st.st_mode) || st.st_uid != getuid()) return false;
  char dir[PATH_MAX], real[PATH_MAX];
  snprintf(dir, sizeof dir, "%s", path);
  *strrchr(dir, '/') = '\0';
  if (lstat(dir, &st) != 0 || !S_ISDIR(st.st_mode)) return false;
  char *slash = strrchr(dir, '/');
  if (!slash || slash == dir) return false;
  *slash = '\0';
  return realpath(dir, real) && strcmp(real, tmp_dir) == 0;
}

static void remove_screen_file(const char *path) {
  char dir[PATH_MAX];
  snprintf(dir, sizeof dir, "%s", path);
  *strrchr(dir, '/') = '\0';
  unlink(path);
  rmdir(dir);
}

static void start_viewer(const char *path) {
  // The programs end the sequence or the character they're writing, or it's cancelled, to write it again after
  double until = now() + SETTLE_WAIT;
  while ((term.state != GROUND || term.utf8_left) && shell_fd >= 0 && now() < until) {
    wait_fd(shell_fd, false, until);
    if (!read_from(shell_fd)) break;
  }
  if (term.state != GROUND) {
    term_write("\x18", 1);
    if (!term.seq_long) buf_add(&held_start, term.seq, term.seq_len);
  }
  term.state = GROUND;
  term.utf8_left = 0;

  pid_t pid = fork_terminal(&viewer_fd);
  if (pid == 0) {
    const char *shell = getenv("SHELL");
    if (!shell || !*shell) shell = "/bin/sh";
    execl(shell, shell, "-c", VIEWER, "nvim", path, (char *)NULL);
    perror(shell);
    _exit(127);
  }
  if (pid < 0) {
    viewer_fd = -1;
    remove_screen_file(path);
    shell_output(held_start.data, held_start.len);
    held_start.len = 0;
    return;
  }
  viewer_pid = pid;
  snprintf(viewer_file, sizeof viewer_file, "%s", path);
}

static void finish_viewer(void) {
  drain(viewer_fd); // what it wrote last, as it left the alternate screen
  if (viewer_fd >= 0) close(viewer_fd);
  viewer_fd = -1;
  viewer_pid = 0;
  viewer_input.len = 0;
  remove_screen_file(viewer_file);

  restore();
  bool on_alt_screen = term.alt_screen;
  shell_output(held_start.data, held_start.len);
  shell_output(held.data, held.len);
  held_start.len = held.len = 0;
  if (held.cap > (1 << 20)) {
    free(held.data);
    held = (struct buf){0};
  }

  // A program still on the alternate screen redraws it at a SIGWINCH, as if the terminal was resized
  if (on_alt_screen && term.alt_screen && shell_fd >= 0) {
    pid_t pgrp = tcgetpgrp(shell_fd);
    if (pgrp > 0) kill(-pgrp, SIGWINCH);
  }
}

//  Input
//-----------------------------------------------
// Passes the input on to the shell, or to Neovim while it runs, but for what C-y sends: F20, a path, and a return.
// Ghostty turns ESC into a space in what's pasted, so that only a key sends F20.
static struct buf pending; // F20 and the path so far, or F20's start at the end of what was read
static bool reading_path;
static double pending_until;

static void send_input(const char *data, size_t len) {
  int fd = viewer_pid ? viewer_fd : shell_fd;
  struct buf *queue = viewer_pid ? &viewer_input : &shell_input;
  if (fd < 0 || len == 0) return;
  buf_add(queue, data, len);
  ssize_t n = write(fd, queue->data, queue->len);
  if (n > 0) buf_drop(queue, n);
}

static void flush_input(int fd, struct buf *queue) {
  ssize_t n = write(fd, queue->data, queue->len);
  if (n > 0) {
    buf_drop(queue, n);
  } else if (n < 0 && errno != EINTR && errno != EAGAIN) {
    queue->len = 0; // the program is gone
  }
}

static void pass_pending(void) {
  send_input(pending.data, pending.len);
  pending.len = 0;
  reading_path = false;
}

static void path_read(void) {
  char path[PATH_MAX];
  size_t len = pending.len - TRIGGER_LEN - 1;
  if (len >= sizeof path) {
    pass_pending();
    return;
  }
  memcpy(path, pending.data + TRIGGER_LEN, len);
  path[len] = '\0';
  if (!screen_file(path)) {
    pass_pending();
    return;
  }
  pending.len = 0;
  reading_path = false;
  if (viewer_pid) {
    remove_screen_file(path);
    send_input("\x19", 1); // C-y
  } else {
    start_viewer(path);
  }
}

static void input(const char *data, size_t len) {
  size_t i = 0;
  while (i < len) {
    if (reading_path) {
      char c = data[i++];
      buf_add(&pending, &c, 1);
      if (c == '\r' || c == '\n') {
        path_read();
      } else if (pending.len > TRIGGER_LEN + PATH_MAX) {
        pass_pending();
      }
      continue;
    }

    // The rest of F20, cut off at the end of the last read
    if (pending.len) {
      while (i < len && pending.len < TRIGGER_LEN && data[i] == TRIGGER[pending.len]) buf_add(&pending, &data[i++], 1);
      if (pending.len == TRIGGER_LEN) {
        reading_path = true;
        pending_until = now() + PATH_WAIT;
      } else if (i < len) {
        pass_pending();
      }
      continue;
    }

    // Up to the next ESC, which may start F20
    const char *esc = memchr(data + i, 0x1b, len - i);
    size_t end = esc ? (size_t)(esc - data) : len;
    send_input(data + i, end - i);
    i = end;
    if (!esc) break;

    // F20, or its start at the end: a lone ESC is the escape key, and goes on at once
    size_t matched = 0;
    while (i + matched < len && matched < TRIGGER_LEN && data[i + matched] == TRIGGER[matched]) matched++;
    if (matched == TRIGGER_LEN || (i + matched == len && matched >= 2)) {
      buf_add(&pending, data + i, matched);
      i += matched;
      reading_path = matched == TRIGGER_LEN;
      pending_until = now() + (reading_path ? PATH_WAIT : PREFIX_WAIT);
    } else {
      send_input(data + i, 1);
      i++;
    }
  }
}

//  Processes
//-----------------------------------------------
static void on_signal(int sig) {
  int saved = errno;
  unsigned char c = sig;
  ssize_t n = write(signal_pipe[1], &c, 1);
  (void)n;
  errno = saved;
}

static void reap(void) {
  int status;
  pid_t pid;
  while ((pid = waitpid(-1, &status, WNOHANG | WUNTRACED)) > 0) {
    if (WIFSTOPPED(status)) {
      kill(pid, SIGCONT); // nothing else would resume them: the shell after suspend, Neovim after C-z
    } else if (pid == viewer_pid) {
      finish_viewer();
    } else if (pid == shell_pid) {
      shell_exited = true;
      shell_status = WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
    }
  }
}

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: ghostty-pane <shell> [<arg>...]\n");
    return 2;
  }
  char *shell = argv[1];
  char **shell_argv = argv + 1;
  char login_name[PATH_MAX];
  if (argv[0][0] == '-') {
    const char *slash = strrchr(shell, '/');
    snprintf(login_name, sizeof login_name, "-%s", slash ? slash + 1 : shell);
    shell_argv[0] = login_name;
  }

  // Without a terminal to pass through, or a pipe for the signals, the shell runs on its own
  if (!isatty(STDIN_FILENO) || tcgetattr(STDIN_FILENO, &tty_saved) != 0 || pipe(signal_pipe) != 0) {
    execvp(shell, shell_argv);
    perror(shell);
    return 127;
  }
  for (int i = 0; i < 2; i++) fcntl(signal_pipe[i], F_SETFD, FD_CLOEXEC);
  fcntl(signal_pipe[1], F_SETFL, O_NONBLOCK);

  const char *tmp = getenv("TMPDIR");
  if (!tmp || !*tmp) tmp = getenv("TMP");
  if (!tmp || !*tmp) tmp = "/tmp";
  if (!realpath(tmp, tmp_dir)) tmp_dir[0] = '\0';

  struct sigaction sa = {0};
  sa.sa_handler = on_signal;
  sigemptyset(&sa.sa_mask);
  sigaction(SIGCHLD, &sa, NULL);
  sigaction(SIGWINCH, &sa, NULL);
  // The terminal is raw, and its programs have their own: nothing to stop or interrupt this
  static const int ignored[] = {SIGINT, SIGQUIT, SIGTSTP, SIGTTIN, SIGTTOU, SIGPIPE};
  for (size_t i = 0; i < sizeof ignored / sizeof ignored[0]; i++) signal(ignored[i], SIG_IGN);

  shell_pid = fork_terminal(&shell_fd);
  if (shell_pid == 0) {
    execvp(shell, shell_argv);
    perror(shell);
    _exit(127);
  }
  if (shell_pid < 0) {
    // No terminal to spare: the shell runs in this one
    for (int sig = 1; sig < NSIG; sig++) signal(sig, SIG_DFL);
    execvp(shell, shell_argv);
    perror(shell);
    return 127;
  }

  struct termios raw = tty_saved;
  cfmakeraw(&raw);
  tcsetattr(STDIN_FILENO, TCSANOW, &raw);

  forget();
  term.title_osc = -1;

  for (;;) {
    if (shell_exited && !viewer_pid) {
      drain(shell_fd);
      quit(shell_status);
    }

    int sfd = shell_fd, vfd = viewer_fd, max = signal_pipe[0];
    fd_set rfds, wfds;
    FD_ZERO(&rfds);
    FD_ZERO(&wfds);
    FD_SET(signal_pipe[0], &rfds);
    if ((viewer_pid ? viewer_input.len : shell_input.len) < INPUT_MAX) FD_SET(STDIN_FILENO, &rfds);
    if (sfd >= 0) {
      if (!viewer_pid || held.len < HOLD_MAX) FD_SET(sfd, &rfds);
      if (shell_input.len) FD_SET(sfd, &wfds);
      if (sfd > max) max = sfd;
    }
    if (vfd >= 0) {
      FD_SET(vfd, &rfds);
      if (viewer_input.len) FD_SET(vfd, &wfds);
      if (vfd > max) max = vfd;
    }
    struct timeval tv = timeval_of(pending_until - now());

    if (select(max + 1, &rfds, &wfds, NULL, pending.len ? &tv : NULL) < 0) {
      if (errno == EINTR) continue;
      quit(1);
    }

    if (FD_ISSET(signal_pipe[0], &rfds)) {
      unsigned char sigs[64];
      ssize_t n = read(signal_pipe[0], sigs, sizeof sigs);
      bool winch = false, chld = false;
      for (ssize_t i = 0; i < n; i++) {
        if (sigs[i] == SIGWINCH) winch = true;
        if (sigs[i] == SIGCHLD) chld = true;
      }
      if (winch) resize();
      if (chld) reap();
    }

    if (FD_ISSET(STDIN_FILENO, &rfds)) {
      char data[4096];
      ssize_t n = read(STDIN_FILENO, data, sizeof data);
      if (n > 0) {
        input(data, n);
      } else if (n == 0 || (errno != EINTR && errno != EAGAIN)) {
        quit(shell_exited ? shell_status : 1); // the terminal is gone
      }
    }

    // What they wrote, and what they can read, unless they're another's by now
    if (sfd >= 0 && sfd == shell_fd) {
      if (FD_ISSET(sfd, &rfds) && !read_from(sfd)) {
        close(sfd);
        shell_fd = -1;
      } else if (FD_ISSET(sfd, &wfds)) {
        flush_input(sfd, &shell_input);
      }
    }
    if (vfd >= 0 && vfd == viewer_fd) {
      if (FD_ISSET(vfd, &rfds) && !read_from(vfd)) {
        close(vfd);
        viewer_fd = -1;
      } else if (FD_ISSET(vfd, &wfds)) {
        flush_input(vfd, &viewer_input);
      }
    }

    if (pending.len && now() >= pending_until) pass_pending();
  }
}
