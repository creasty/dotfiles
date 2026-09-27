# Neovim end-to-end workflow tests

An executable spec of how this Neovim setup behaves. Every test boots a real
Neovim with this repository's `nvim/` config and the installed plugins, types
keys into it, and checks what you would see: buffer text, cursor, mode,
popups, pickers, signs, the statusline.

The specs describe workflows ("`<Esc>` closes the completion menu but stays in
insert mode"), not plugins. A thin adapter layer is the only code that knows
which plugin provides a behavior, so the same specs keep running while you
replace a plugin — and fail exactly where your workflow changes. That is how
coc.nvim, ddu, UltiSnips, lexima and copilot.vim were replaced by Neovim's LSP
client with blink.cmp, snacks.nvim's picker, LuaSnip, nvim-autopairs and
copilot.lua.

## Running

```sh
nvim/tests/run                      # everything: ~670 tests, ~50s with 4 workers
nvim/tests/run completion lsp       # spec files whose name contains a word
nvim/tests/run -f 'Esc' -f scroll   # tests whose full name matches a Lua pattern (any -f)
nvim/tests/run -l                   # list the requirements (-q adds quirk notes)
nvim/tests/run -v                   # print every test, not just failures
nvim/tests/run --update-golden snippet_library   # re-pin golden output
```

`run --help` shows all options. A failure prints the assertion, the child's
screen and its `:messages`.

Needs what the config itself needs: Neovim 0.11.3 or later, the installed
dein plugins (found through `~/.config/nvim/dein/repos`, or set
`E2E_DEIN_REPOS`), Ruby's `erb`, git, fd, rg and ghq. No language server,
formatter or linter is needed: the fakes stand in for them. Temporary files go
to `$E2E_TMPDIR` (default `$TMPDIR`), which must not be inside a project such
as a git repository: the config finds project roots by walking up from a file.

## Plugin versions

`nvim/dein/lock.json` pins what is installed on your machine: the commit of
every dein plugin and the revision of every tree-sitter parser. CI installs
exactly that.

```sh
nvim/tests/plugins check      # do the installed plugins match lock.json?
nvim/tests/plugins lock       # re-pin after updating plugins, then commit it
nvim/tests/plugins install    # install exactly the pinned versions (what CI runs)
```

`install` clones into `$E2E_DEIN_REPOS` (default `nvim/dein/repos`) and builds
the parsers. It never changes a plugin that is already installed at another
commit.

`lock` warns about plugins whose repository it cannot reach (a fresh install
could not clone them either). To keep one pinned anyway, give its entry a
`"mirror"` that has the same commit; `install` fetches from it and `lock`
keeps it.

## CI

`.github/workflows/nvim-e2e.yml` runs the suite on macOS for pull requests and
pushes to master that touch `nvim/` or `bin/`, with the versions this setup was
pinned on (Neovim 0.11.7, and tree-sitter CLI 0.25.3 on Node 20.18.2 to build
parsers) and the plugins in `lock.json`. The job summary
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
| `lsp` | `gd gt gi gD gT gR gll gh gr gq`, diagnostics, `:Format`, `:Import`, which TypeScript server starts, spell checking settings | **Neovim's LSP client**, conform.nvim, **snacks.nvim** |
| `snippets` | `<Tab>` expansion, placeholders, postfix/arrow/heading snippets | **LuaSnip** |
| `snippet_library_*` | golden expansion of every snippet in `nvim/snippets` | **LuaSnip** |
| `ai` | ghost text, `<C-s><C-j>` accept, `<Esc>`/`<C-s><C-c>` dismiss | **copilot.lua** |
| `picker` | `<C-q>` files / ghq repos, `<Space>/` grep, list keys | **snacks.nvim** |
| `picker_checklist` | every source × reopen as left, own state, scroll, `<C-l>`, `<C-r>` (below) | **snacks.nvim** |
| `integration` | no pairs/completion/AI in picker prompts and block inserts | `user/intelligence.lua` |
| `ui` | tabline, statusline, title, signs (marks, git), whitespace | `user/ui.lua`, gitsigns.nvim |
| `files`, `navigation`, `text_ops`, `treesitter`, `filetypes`, `templates` | everything else | various |

The files named above are under `nvim/lua/`; `user/intelligence.lua` is where
completion, snippets, auto-pairs and AI suggestions share the insert-mode keys.

### Picker checklist

Every picker source is checked for the same things:

| | files<br>`<C-q>` | repositories<br>`<C-q>` in `$HOME` | grep<br>`<Space>/` | locations<br>`gR` `gD` `gT`, `gll` |
|---|---|---|---|---|
| focus when opened | prompt | prompt | list | list |
| reopens as left: query, results, selected line, focus | ✓ | ✓ | ✓ and marks | ✓ |
| keeps its own state while others are used | ✓ | ✓ | ✓ | ✓ |
| a long list scrolls; reopens at the selected line, where it was | `<C-n>` `<C-p>` | `<C-n>` `<C-p>` | `j` `k` `<Down>` `<Up>` | `j` `k` |
| `<C-l>`: refresh, first line selected | new files, same query | new repositories, same query | searches again | asks the language server again |
| `<C-r>`: reload | clears the query, lists every file | clears the query, lists every repository | asks for a new pattern (`<Esc>` keeps the search) | clears the query |

A picker opened after `:cd` starts fresh, and so does one opened back in the
first directory. `<Tab>` lists the actions for the item; `q` there returns to
the picker as you left it.

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
     suggest), picker (items, visible lines, selection, marks, query, focus),
     signs, highlights. It already recognizes blink.cmp, nvim-cmp, the
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
`golden/snippets/*.snippets.txt`: it was recorded with UltiSnips and checked
against the converted LuaSnip library. With a placeholder selected, the
recorded cursor sits on its last character, whichever end of the selection an
engine leaves the cursor at.

## How it works

- **Isolation.** Each child gets its own XDG state/cache directories (XDG
  data is per run), an in-memory clipboard, a fake `trash`, and no shada.
  Your real state is never touched. The config directory is a tree of
  symlinks to this working tree, cached per working tree (with dein's state
  cache) in `$TMPDIR/nvim-e2e-cache/`.
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
