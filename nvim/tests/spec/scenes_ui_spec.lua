-- Scenes of the editor's UI, whatever the language: signs, diagnostics, completion and the AI's suggestions,
-- selections, diffs, the picker and the explorer, each compared with its snapshot in golden/scenes/ui/ (README.md,
-- "Scenes").
local t = require('t')
local probe = require('probe')
local scenes = require('scenes').set('ui', 'Scenes: the UI')
local describe, it = t.describe, t.it

-- palette.go as committed, then as changed: a type's comment deleted, a check added, a line changed, and comments
-- with the words the fake language server reports diagnostics on
local COMMITTED = {
  'package palette',
  '',
  'import (',
  '	"fmt"',
  '	"math"',
  ')',
  '',
  '// Palette spaces its levels evenly in OKLCH lightness.',
  'type Palette struct {',
  '	dark, step float64',
  '	hues       map[string]Hue',
  '}',
  '',
  'type Hue struct {',
  '	Angle, Sat float64',
  '}',
  '',
  '// Scale returns the color at a level: 100 (lightest) to 900.',
  'func (p *Palette) Scale(name string, level int) (string, error) {',
  '	hue, ok := p.hues[name]',
  '	if !ok {',
  '		return "", fmt.Errorf("no hue %q", name)',
  '	}',
  '	l := p.dark + float64(900-level)/100*p.step',
  '	c := math.Min(hue.Sat*l, 0.4)',
  '	return fmt.Sprintf("oklch(%.3f %.3f %.0f)", l, c, hue.Angle), nil',
  '}',
  '',
  'func (p *Palette) Levels() []int {',
  '	levels := make([]int, 0, 9)',
  '	for level := 100; level <= 900; level += 100 {',
  '		levels = append(levels, level)',
  '	}',
  '	return levels',
  '}',
}
local CHANGED = vim.list_extend({}, COMMITTED)
table.remove(CHANGED, 8)
CHANGED[24] = '	c := math.Min(hue.Sat*l, maxChroma) // ERROR, TODO: clamp to sRGB  '
CHANGED[33] = '	return levels // INFO HINT'
for i, line in ipairs({
  '	if level < 100 || level > 900 { // WARNING',
  '		return "", fmt.Errorf("level %d: out of range", level)',
  '	}',
}) do
  table.insert(CHANGED, 22 + i, line)
end

--- Runs git in the sandbox, isolated from the user's git config.
local function git(nvim, ...)
  local res = vim.system(vim.list_extend({ 'git' }, { ... }), {
    cwd = nvim.dir,
    text = true,
    env = {
      GIT_CONFIG_NOSYSTEM = '1',
      GIT_CONFIG_GLOBAL = '/dev/null',
      GIT_AUTHOR_NAME = 'e2e',
      GIT_AUTHOR_EMAIL = 'e2e@example.com',
      GIT_COMMITTER_NAME = 'e2e',
      GIT_COMMITTER_EMAIL = 'e2e@example.com',
    },
  }):wait()
  assert(res.code == 0, 'git ' .. table.concat({ ... }, ' ') .. ': ' .. (res.stderr or ''))
end

--- A Go project in git, palette.go changed since its commit, and a directory and a file git ignores.
local function project(scene)
  local nvim = scenes.nvim(scene)
  nvim:files({
    ['.gitignore'] = { 'dist/', 'debug.log' },
    ['go.mod'] = { 'module example.com/palette', '', 'go 1.24' },
    ['palette.go'] = COMMITTED,
    ['palette_test.go'] = { 'package palette', '', 'import "testing"', '', 'func TestScale(t *testing.T) {}' },
    ['cmd/candle/main.go'] = { 'package main', '', 'func main() {}' },
    ['README.md'] = { '# palette' },
  })
  git(nvim, 'init', '-q', '-b', 'main')
  git(nvim, 'add', '-A')
  git(nvim, 'commit', '-q', '-m', 'init')
  nvim:files({ ['palette.go'] = CHANGED, ['dist/out.js'] = 'x', ['debug.log'] = 'x' })
  return nvim
end

--- Opens palette.go, once its diagnostics and git signs are in.
local function open_palette(nvim)
  nvim:edit('palette.go')
  probe.wait_lsp(nvim)
  probe.wait_git(nvim)
  nvim:wait_for(function()
    return probe.diagnostics(nvim).error > 0
  end, { message = 'the diagnostics' })
end

describe('Scenes: the UI', function()
  it('the editor: git signs, diagnostics, a search, tabs', function()
    local nvim = project('editor')
    nvim:cmd('tabedit palette_test.go')
    nvim:cmd('tabprevious')
    open_palette(nvim)
    nvim:type('gg/level<CR>')
    scenes.check(nvim, 'editor', 'The editor: git signs, diagnostics (signs, undercurls), a search (the match at the cursor, the others), tabs')
  end)

  it('a diagnostic float', function()
    local nvim = project('diagnostic-float')
    open_palette(nvim)
    nvim:type('gg]e')
    scenes.check(nvim, 'diagnostic-float', 'Resting on an error: its float')
  end)

  it('completion', function()
    local nvim = project('completion')
    open_palette(nvim)
    nvim:type('25Go')
    probe.wait_ai(nvim)
    nvim:type('x := e2e')
    probe.wait_completion(nvim, { item = 'e2eGamma' })
    nvim:type('<C-n>')
    scenes.check(nvim, 'completion', "Completion: the menu (the selected item, the matched letters), the item's documentation and ghost text")
  end)

  it("the AI's suggestion", function()
    local nvim = project('ai-suggestion')
    open_palette(nvim)
    nvim:type('35Go')
    probe.wait_ai(nvim)
    nvim:type('return ')
    probe.wait_ghost(nvim, "'from ai';")
    scenes.check(nvim, 'ai-suggestion', "The AI's suggestion: ghost text")
  end)

  it('a visual selection', function()
    local nvim = project('visual')
    open_palette(nvim)
    nvim:type('26GV2j')
    scenes.check(nvim, 'visual', 'A visual selection')
  end)

  it('a diff', function()
    local nvim = project('diff')
    open_palette(nvim)
    nvim:cmd('DiffviewOpen')
    probe.wait_diff_view(nvim, function(view)
      return #view.sides == 2
    end)
    scenes.check(nvim, 'diff', 'A diff (Diffview): the lines added, changed and deleted, the text changed, the selected file')
  end)

  it('the file picker', function()
    local nvim = project('file-picker')
    open_palette(nvim)
    probe.wait_picker_ready(nvim)
    nvim:type('<C-q>')
    probe.wait_picker(nvim)
    nvim:type('pal')
    probe.wait_picker(nvim, function(p)
      return #p.items == 2
    end)
    nvim:type('<C-n>')
    scenes.check(nvim, 'file-picker', 'The file picker: the selected line, the matched letters')
  end)

  it('the explorer', function()
    local nvim = project('explorer')
    nvim:cmd('edit .')
    -- (each refresh of the list puts the cursor back, so `jj` waits for both: git's status hiding what it ignores,
    -- then `I` showing it)
    probe.wait_picker(nvim, function(p)
      return p.source == 'explorer' and #p.items == 7
    end)
    nvim:type('I')
    probe.wait_picker(nvim, function(p)
      return #p.items == 9
    end)
    nvim:type('jj')
    scenes.check(nvim, 'explorer', 'The explorer: the selected line, what git ignores dimmed')
  end)
end)
