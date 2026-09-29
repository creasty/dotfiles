# Neovim end-to-end workflow tests

An executable spec of how this Neovim setup behaves. Every test boots a real
Neovim with this repository's `nvim/` config and the installed plugins, types
keys into it, and checks what you would see: buffer text, cursor, mode,
popups, pickers, signs, the statusline.

The specs describe workflows ("`<Esc>` closes the completion menu but stays in
insert mode"), not plugins. A thin adapter layer is the only code that knows
which plugin provides a behavior, so the same specs keep running while you
replace a plugin — and fail exactly where your workflow changes.

## Running

```sh
nvim/tests/run                      # everything: ~670 tests, about a minute with 4 workers
nvim/tests/run completion lsp       # spec files whose name contains a word
nvim/tests/run -f 'Esc' -f scroll   # tests whose full name matches a Lua pattern (any -f)
nvim/tests/run -l                   # list the requirements (-q adds quirk notes)
nvim/tests/run -v                   # print every test, not just failures
nvim/tests/run --update-golden snippet_library   # re-pin golden output
```

`run --help` shows all options. A failure prints the assertion, the child's
screen and its `:messages`.

Needs what the config itself needs: Neovim 0.12 or later, the installed plugins
(found where lazy.nvim installs them, `~/.local/share/nvim/lazy`, or set
`E2E_PLUGINS`), Ruby's `erb`, git, fd, rg and ghq. No language server,
formatter or linter is needed: the fakes stand in for them. Temporary files go
to `$E2E_TMPDIR` (default `$TMPDIR`), which must not be inside a project such
as a git repository: the config finds project roots by walking up from a file.
Nor under `/tmp` or `/private`, where Neovim 0.12 keeps no cursor positions
(`'shada'`): on macOS, whose `$TMPDIR` resolves to `/private/var/folders/…`,
set `E2E_TMPDIR`, or the test that reopens a file fails.

## Plugin versions

`nvim/flake.lock` pins the commit of every plugin, which lazy.nvim installs
on your machine and CI installs too. The tree-sitter parsers follow: each is
built at the revision the pinned nvim-treesitter's table of parsers gives it
(as `:TSUpdate` does). Dependabot bumps the pins in pull requests, so each shows
which workflows the new commits change; after pulling one, Neovim checks them
out when it next starts, and rebuilds the parsers they change. A plugin
lazy.nvim loads from your working copy (`dev` in `nvim/lua/user/plugins.lua`)
is yours to keep at any commit, and CI installs its pin instead.

```sh
nvim/tests/plugins check      # do the installed plugins and parsers match the pins?
nvim/tests/plugins install    # install exactly the pinned versions (what CI runs)
```

`install` clones into `$E2E_PLUGINS` (default: lazy.nvim's root) and builds
the parsers with the tree-sitter CLI. It never changes a plugin that is already
installed at another commit.

A pinned repository that disappears breaks fresh installs, though not CI's
cached plugins: point its input in `nvim/flake.nix` and its spec at a fork or
mirror that has the commit.

## CI

The `nvim-e2e` job of `.github/workflows/tests.yml` runs the suite on macOS for
pull requests, pushes to master and every Monday, with the versions this setup
was pinned on (Neovim 0.12.4, and tree-sitter CLI 0.26.8 to build parsers:
those nixpkgs installs) and the plugins `nvim/flake.lock` pins. The job summary
lists every workflow that changed: the assertion, the child's screen, and
whether the test was a pinned quirk (`run --summary FILE` writes it).

## What is covered

| Spec | Workflows | Provided today by |
|---|---|---|
| `startup` | quiet boot, startup time budget, options, commands | init.vim |
| `editing`, `windows` | init.vim keymaps, submodes, `<C-s>` window keys, tags | init.vim, `plugin/` |
| `emacs_keys` | insert/cmdline/select-mode Emacs keys | `plugin/emacs_cursor.vim` |
| `autopairs` | pairs, step-over, `<CR>`/`<Space>` rules, custom rules, dot repeat | **nvim-autopairs**, `user/plugin/autopairs.lua` |
| `cmdline` | `:'`, `:w!!`, `:ee`…, `:s/` family, search escaping, abbreviations | `user/cmdline.lua`, live-command |
| `completion` | popup, `<Tab>`/`<CR>`/`<Esc>`/`<C-n>`, sources, LSP snippets | **blink.cmp**, **LuaSnip** |
| `lsp` | `gd gt gi gD gT gR gll gh gr gq`, diagnostics, `:Format`, `:Import`, which TypeScript server starts, spelling as hints | **Neovim's LSP client**, conform.nvim, **snacks.nvim** |
| `snippets` | `<Tab>` expansion, placeholders, postfix/arrow/heading snippets | **LuaSnip** |
| `snippet_library_*` | golden expansion of every snippet in `nvim/snippets` | **LuaSnip** |
| `ai` | ghost text, `<C-s><C-j>` accept, `<Esc>`/`<C-s><C-c>` dismiss | **copilot.lua** |
| `picker` | `<C-q>` files / ghq repos, `<Space>/` grep, the files it searches (`f`), replace (`r` `x` `R`), list keys, short screens | **snacks.nvim** |
| `picker_checklist` | every source × reopen as left, own state, scroll, `<C-l>`, `<C-r>` (below) | **snacks.nvim** |
| `integration` | no pairs/completion/AI in picker prompts and block inserts | `user/intelligence.lua` |
| `ui` | tabline, statusline, title, signs (marks, git), whitespace, Ghostty's screen (copy mode) | `user/ui.lua`, gitsigns.nvim, `ftplugin/ghosttyscreen.vim` |
| `files`, `navigation`, `text_ops`, `treesitter`, `filetypes`, `templates` | everything else | various |

The files named above are under `nvim/lua/`; `user/intelligence.lua` is where
completion, snippets, auto-pairs and AI suggestions share the insert-mode keys.

### Picker checklist

Every picker source is checked for the same things:

| | files<br>`<C-q>` | repositories<br>`<C-q>` in `$HOME` | grep<br>`<Space>/` | locations<br>`gR` `gD` `gT`, `gll` |
|---|---|---|---|---|
| focus when opened | prompt | prompt | list | list |
| `<C-c>` in the prompt | closes | closes | back to the list, still narrowed (`<Esc>` too) | back to the list, still narrowed (`<Esc>` too) |
| reopens as left: query, results, selected line, focus | ✓ | ✓ | ✓ and marks | ✓ |
| keeps its own state while others are used | ✓ | ✓ | ✓ | ✓ |
| a long list scrolls; reopens at the selected line, where it was | `<C-n>` `<C-p>` | `<C-n>` `<C-p>` | `j` `k` `<Down>` `<Up>` | `j` `k` |
| `<C-l>`: refresh, first line selected | new files, same query | new repositories, same query | searches again | asks the language server again |
| `<C-r>`: reload | clears the query, lists every file | clears the query, lists every repository | asks for a new pattern (`<Esc>` keeps the search) | clears the query |

A picker opened after `:cd` starts fresh, and so does one opened back in the
first directory.

Grep also reopens with the files it searches (`f`), the replacement its list
previews (`r`) and the lines dropped from it (`x`); `<C-l>` and `<C-r>` bring
the dropped lines back, and a new search (`:Search`) starts with none of
them.

Tests marked **[quirk]** pin an oddity of today's setup instead of a
requirement (e.g. "html: typing a tag leaves a stray >").
`run -l -q` lists them with the reason. When one fails after a change, the new
behavior may well be the better one: update or delete the test.

## When you replace a plugin

1. Start from a green run.
2. Swap the plugin in the config.
3. Adapt the seam — not the specs:
   - `lib/probe_child.lua` — how to *observe* plugin UI: completion menu,
     snippet session, ghost text (and whether the AI client is ready to
     suggest), picker (items, visible lines, selection, marks, query, focus,
     title; struck-through text, as a replacement's preview shows it, reads
     `{-text-}`), signs, highlights. It already recognizes blink.cmp, nvim-cmp, the
     built-in popup menu, LuaSnip, `vim.snippet`, snacks.nvim's picker
     (through its API: its list is drawn lazily) and Telescope-style pickers
     whose list is a buffer of results.
   - `lib/prelude.lua` — how to *point* plugins at the fakes: the fake server
     is `vim.lsp.config('e2e', ...)` and the only one `vim.lsp.enable()` takes;
     conform.nvim and nvim-lint run no external formatter or linter.
   - `lib/env.lua` — fake executables on `PATH` (`trash`, and
     `copilot-language-server`, which runs `fakes/copilot.lua`; it speaks
     copilot-language-server's protocol), and the plugin manager or install
     location.
   - `lib/warmup.lua` — first-use warm-up (only needed for slow starters).
4. Run the suite. Each failure is a workflow that changed: fix the config, or
   update the spec if the change is what you want.

The snippet library is pinned trigger by trigger in
`golden/snippets/*.snippets.txt`. With a placeholder selected, the recorded
cursor sits on its last character, whichever end of the selection an engine
leaves the cursor at.

## How it works

- **Isolation.** Each child gets its own XDG state/cache directories (XDG
  data is per run), an in-memory clipboard, a fake `trash`, and no shada.
  Your real state is never touched. The config directory is a tree of
  symlinks to this working tree, and lazy.nvim's root a link to the installed
  plugins. With empty caches, a child compiles every Lua module it loads, so
  the startup budget is checked once a first boot has filled them, as your
  starts find them.
- **Fakes.** `fakes/lsp.lua` is a deterministic language server (its header
  documents what "definition", "references", etc. mean), the only one the
  children start. `fakes/copilot.lua` suggests only after a few fixed
  phrases, so no other test sees ghost text.
- **UI.** Children run headless, so no UI attaches. When one does, Neovim
  fires `UIEnter` after `VimEnter`, and some plugins finish setting up then
  (snacks.nvim takes over `vim.ui.select`), so `lib/prelude.lua` fires it the
  same way.
- **Keys.** `nvim:type(keys)` is one burst of typing followed by a pause. The
  pause resolves a pending key sequence the way moving on does — including
  submodes such as `gee` or `<C-s>+++`, which never time out in Neovim — so
  type a whole submode chain in one call. A literal `<` is `<lt>`.
- **Timing.** Asynchronous results are awaited with `nvim:wait_for()` and the
  `probe.wait_*()` helpers (`wait_picker` also waits for the picker to finish
  loading). Where a person would pause (between closing and reopening a
  picker, before typing into a fresh placeholder), the tests pause too.
  Typed while Neovim is still busy (a menu just opened), `<C-c>` interrupts
  instead of running its mapping (`:help map_CTRL-C`), so pause before it. An
  accepted completion item lands a moment after the key (blink.cmp may
  resolve it with the server first), so wait for the text. Tests that race a
  plugin's own internals can be marked `retry`, with a random back-off; a
  real regression fails every attempt.

## Writing tests

```lua
local t = require('t')
local probe = require('probe')

t.describe('Completion', function()
  t.it('<Tab> accepts the first item', function()
    local nvim = t.nvim()                       -- fresh child, closed afterwards
    nvim:files({ ['.git/'] = true })            -- files in its sandbox directory
    nvim:edit('main.go', { 'package main', '' })
    probe.wait_lsp(nvim)                        -- fake server attached
    nvim:type('Goe2eB')
    probe.wait_completion(nvim, { item = 'e2eBeta' })
    nvim:type('<Tab>')
    nvim:wait_for(function()                    -- the item lands a moment later
      return nvim:line(3) == 'e2eBeta'
    end)
    t.buffer(nvim, { 'package main', '', 'e2eBeta|' })   -- | marks the cursor
  end)
end)
```

- Child: `type`, `set_buffer`, `buffer`, `lines`, `line`, `cursor`, `mode`,
  `wait_for`, `wait_mode`, `cmd`, `exec`, `eval`, `call`, `lua`, `edit`,
  `files`, `path`, `read_file`, `floats`, `screen`, `statusline`, `tabline`,
  `messages`, `getreg` (see `lib/child.lua`).
- Assertions: `eq`, `neq`, `ok`, `no`, `match`, `no_match`, `contains`,
  `buffer`, `golden_section` (see `lib/t.lua`).
- Options: `t.it(name, fn, { timeout = ms, retry = n })`,
  `t.quirk(name, reason, fn)`.
