# Neovim end-to-end workflow tests

An executable spec of how this Neovim setup behaves. Every test boots a real
Neovim with this repository's `nvim/` config and the installed plugins, types
keys into it, and checks what you would see: buffer text, cursor, mode,
popups, pickers, signs, the statusline.

The specs describe workflows ("`<Esc>` closes the completion menu but stays in
insert mode"), not plugins. A thin adapter layer is the only code that knows
which plugin provides a behavior, so the same specs keep running while you
replace coc.nvim, ddu, copilot.vim, UltiSnips or lexima — and fail exactly
where your workflow changes.

## Running

```sh
nvim/tests/run                      # everything: ~675 tests, ~90s with 4 workers
nvim/tests/run completion lsp       # spec files whose name contains a word
nvim/tests/run -f 'Esc' -f scroll   # tests whose full name matches a Lua pattern (any -f)
nvim/tests/run -l                   # list the requirements (-q adds quirk notes)
nvim/tests/run -v                   # print every test, not just failures
nvim/tests/run --update-golden snippet_library   # re-pin golden output
```

`run --help` shows all options. A failure prints the assertion, the child's
screen and its `:messages`.

Needs what the config itself needs: Neovim 0.11, the installed dein plugins
(found through `~/.config/nvim/dein/repos`, or set `E2E_DEIN_REPOS`),
`coc-snippets` and `coc-git` in `~/.config/coc/extensions`
(`E2E_COC_EXTENSIONS`), Node, Deno, Python 3 with pynvim, Ruby's `erb`, git,
fd, rg and ghq. The first run downloads and compiles the denops plugins into a
test-owned Deno cache (about 20s); later runs reuse it. Temporary files go to
`$E2E_TMPDIR` (default `$TMPDIR`), which must not be inside a project such as
a git repository: the config finds project roots by walking up from a file.

## Plugin versions

`nvim/dein/lock.json` pins what is installed on your machine: the commit of
every dein plugin, the revision of every tree-sitter parser, and the version of
the coc extensions the specs use. CI installs exactly that.

```sh
nvim/tests/plugins check      # do the installed plugins match lock.json?
nvim/tests/plugins lock       # re-pin after updating plugins, then commit it
nvim/tests/plugins install    # install exactly the pinned versions (what CI runs)
```

`install` clones into `$E2E_DEIN_REPOS` (default `nvim/dein/repos`), builds the
parsers, and installs the coc extensions into `$E2E_COC_EXTENSIONS` when set.
It never changes a plugin that is already installed at another commit.

`lock` warns about plugins whose repository it cannot reach (a fresh install
could not clone them either). To keep one pinned anyway, give its entry a
`"mirror"` that has the same commit; `install` fetches from it and `lock`
keeps it.

## CI

`.github/workflows/nvim-e2e.yml` runs the suite on macOS for pull requests and
pushes to master that touch `nvim/` or `bin/`, with the versions this setup was
pinned on (Neovim 0.11.0, Node 20.18.2, Deno 2.2.6, Python 3.9 with pynvim
0.4.3, tree-sitter CLI 0.25.3) and the plugins in `lock.json`. The job summary
lists every workflow that changed: the assertion, the child's screen, and
whether the test was a pinned quirk (`run --summary FILE` writes it).

## What is covered

| Spec | Workflows | Provided today by |
|---|---|---|
| `startup` | quiet boot, startup time budget, options, commands | init.vim |
| `editing`, `windows` | init.vim keymaps, submodes, `<C-s>` window keys, tags | init.vim, `plugin/` |
| `emacs_keys` | insert/cmdline/select-mode Emacs keys | `plugin/emacs_cursor.vim` |
| `autopairs` | pairs, step-over, `<CR>`/`<Space>` rules, custom rules, dot repeat | **lexima** |
| `cmdline` | `:'`, `:w!!`, `:ee`…, `:s/` family, search escaping, abbreviations | **lexima**, live-command |
| `completion` | popup, `<Tab>`/`<CR>`/`<Esc>`/`<C-n>`, sources, LSP snippets | **coc.nvim** |
| `lsp` | `gd gt gi gD gT gR gll gh gr gq`, diagnostics, `:Format`, `:Import` | **coc.nvim**, **ddu** |
| `snippets` | `<Tab>` expansion, placeholders, postfix/arrow/heading snippets | **UltiSnips** |
| `snippet_library_*` | golden expansion of every snippet in `nvim/ultisnips` | **UltiSnips** |
| `ai` | ghost text, `<C-s><C-j>` accept, `<Esc>`/`<C-s><C-c>` dismiss | **copilot.vim** |
| `picker` | `<C-q>` files / ghq repos, `<Space>/` grep, list keys | **ddu** |
| `picker_checklist` | every source × reopen as left, own state, scroll, `<C-l>`, `<C-r>` (below) | **ddu** |
| `integration` | no pairs/completion/AI in picker prompts and block inserts | glue in init.vim |
| `files`, `navigation`, `text_ops`, `treesitter`, `filetypes`, `templates`, `ui` | everything else | various |

### Picker checklist

Every picker source is checked for the same things:

| | files<br>`<C-q>` | repositories<br>`<C-q>` in `$HOME` | grep<br>`<Space>/` | locations<br>`gR` `gD` `gT`, `gll` |
|---|---|---|---|---|
| focus when opened | prompt | prompt | list | list |
| reopens as left: query, results, selected line, focus | ✓ | ✓ | ✓ and marks | ✓ ¹ |
| keeps its own state while others are used | ✓ | ✓ | ✓ | ✓ |
| a long list scrolls; reopens at the selected line ² | `<C-n>` `<C-p>` | `<C-n>` `<C-p>` | `j` `k` `<Down>` `<Up>` | `j` `k` |
| `<C-l>`: refresh | new files, same query, first line | new repositories, same query, first line | searches again ³ | same locations ³ |
| `<C-r>`: reload | lists every file ⁴ | lists every repository ⁴ | asks for a new pattern ⁵ | clears the narrowing ⁴ |

A picker opened after `:cd` starts fresh. Quirks pinned along the way:
¹ the first `gll` after startup starts at the top;
² the selected line comes back in the middle of the window, not where it was;
³ from the list, the selection stays on the same item (and locations are not
requested again); ⁴ the old query stays in the prompt though it no longer
filters; ⁵ `<Esc>` at that prompt makes the next `<Space>/` ask again. Also:
the repository list ends with an empty entry, and after `<Tab>` and `q` the
list comes back with the first line selected.

Tests marked **[quirk]** pin an oddity of today's setup instead of a
requirement (e.g. "leaving a Go buffer formats the buffer you switch to").
`run -l -q` lists them with the reason. When one fails after a change, the new
behavior may well be the better one: update or delete the test.

## When you replace a plugin

1. Start from a green run.
2. Swap the plugin in the config.
3. Adapt the seam — not the specs:
   - `lib/probe_child.lua` — how to *observe* plugin UI: completion menu,
     snippet session, ghost text, picker (items, visible lines, selection,
     marks, query), signs, highlights. It already
     recognizes blink.cmp, nvim-cmp, the built-in popup menu, LuaSnip,
     `vim.snippet`, and Telescope/snacks picker buffers.
   - `lib/prelude.lua` — how to *point* plugins at the fakes. For native LSP,
     replace the coc `languageserver` entry with
     `vim.lsp.config('e2e', { cmd = { ctx.nvim, '--clean', '-l', ctx.fakes.lsp }, filetypes = LSP_FILETYPES })`
     plus `vim.lsp.enable('e2e')`; for another Copilot client, make its server
     command `fakes/copilot.lua` (it speaks copilot-language-server's protocol).
   - `lib/warmup.lua` — first-use warm-up (only needed for slow starters).
   - `lib/env.lua` — only if the plugin manager or install location changes.
4. Run the suite. Each failure is a workflow that changed: fix the config, or
   update the spec if the change is what you want.

The snippet library is pinned trigger by trigger in
`golden/snippets/*.snippets.txt`, so a converted library can be checked the
same way.

## How it works

- **Isolation.** Each child gets its own XDG state/cache directories and coc
  data (XDG data is per run), an in-memory clipboard, a fake `trash`, and no
  shada. Your real state is never touched. The config directory is a tree of
  symlinks to this working tree, cached per working tree (with its Deno
  cache) in `$TMPDIR/nvim-e2e-cache/`.
- **Fakes.** `fakes/lsp.lua` is a deterministic language server (its header
  documents what "definition", "references", etc. mean). `fakes/copilot.lua`
  suggests only after a few fixed phrases, so no other test sees ghost text.
- **Keys.** `nvim:type(keys)` is one burst of typing followed by a pause. The
  pause resolves a pending key sequence the way moving on does — including
  submodes such as `gee` or `<C-s>+++`, which never time out in Neovim — so
  type a whole submode chain in one call. A literal `<` is `<lt>`.
- **Timing.** Asynchronous results are awaited with `nvim:wait_for()` and the
  `probe.wait_*()` helpers (`wait_picker` also waits for the picker to finish
  loading). Where a person would pause (between closing and reopening a
  picker, before typing into a fresh placeholder), the tests pause too. A few
  tests race a plugin's own internals (coc's snippet sessions) and are marked
  `retry`, with a random back-off; a real regression fails every attempt.

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
