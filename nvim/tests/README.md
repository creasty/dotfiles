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
nvim/tests/run                      # everything: ~650 tests, ~70s with 4 workers
nvim/tests/run completion lsp       # spec files whose name contains a word
nvim/tests/run -f 'Esc'             # tests whose full name matches a Lua pattern
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
test-owned Deno cache (about 20s); later runs reuse it.

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
| `picker` | `<C-q>` files / ghq repos, `<Space>/` grep, list keys, resume | **ddu** |
| `integration` | no pairs/completion/AI in picker prompts and block inserts | glue in init.vim |
| `files`, `navigation`, `text_ops`, `treesitter`, `filetypes`, `templates`, `ui` | everything else | various |

Tests marked **[quirk]** pin an oddity of today's setup instead of a
requirement (e.g. "leaving a Go buffer formats the buffer you switch to").
`run -l -q` lists them with the reason. When one fails after a change, the new
behavior may well be the better one: update or delete the test.

## When you replace a plugin

1. Start from a green run.
2. Swap the plugin in the config.
3. Adapt the seam — not the specs:
   - `lib/probe_child.lua` — how to *observe* plugin UI: completion menu,
     snippet session, ghost text, picker, signs, highlights. It already
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

- **Isolation.** Children get their own XDG data/state/cache directories,
  an in-memory clipboard, a fake `trash`, their own coc data and Deno cache,
  and no shada. Your real state is never touched. The config directory is a
  tree of symlinks to this working tree, cached per working tree in
  `$TMPDIR/nvim-e2e-cache/`.
- **Fakes.** `fakes/lsp.lua` is a deterministic language server (its header
  documents what "definition", "references", etc. mean). `fakes/copilot.lua`
  suggests only after a few fixed phrases, so no other test sees ghost text.
- **Keys.** `nvim:type(keys)` is one burst of typing followed by a pause. The
  pause resolves a pending key sequence the way moving on does — including
  submodes such as `gee` or `<C-s>+++`, which never time out in Neovim — so
  type a whole submode chain in one call. A literal `<` is `<lt>`.
- **Timing.** Asynchronous results are awaited with `nvim:wait_for()` and the
  `probe.wait_*()` helpers. A few tests race a plugin's own internals (coc's
  snippet sessions) and are marked `retry`; a real regression fails them all.

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
