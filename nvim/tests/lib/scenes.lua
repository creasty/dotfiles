-- Scenes: screens captured cell by cell as kitty shows them, each compared with
-- its snapshot, on a page that shows one or the other (README.md, "Scenes").
local t = require('t')
local env = require('env')
local probe = require('probe')

local M = {}

local UPDATE = os.getenv('E2E_UPDATE_GOLDEN') == '1'

-- kitty's colors: where Neovim sets none, and the cursor's
local KITTY = {}
for line in env.read_file(env.repo_dir .. '/config/kitty/candle.conf'):gmatch('[^\n]+') do
  local option, color = line:match('^(%S+)%s+(#%x+)$')
  if option then
    KITTY[option] = color
  end
end

---------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------

--- The screen as its snapshot keeps it: JSON, a line for each style and each
--- row, a row being runs of { style, text } (style: an index into the styles).
local function snapshot(screen)
  local styles, ids, rows = {}, {}, {}
  for _, cells in ipairs(screen.rows) do
    local runs = {}
    for _, cell in ipairs(cells) do
      -- (a wide character's second cell has no text)
      if cell[1] ~= '' then
        local style = { unpack(cell, 2) }
        local key = table.concat(style, ' ')
        if not ids[key] then
          table.insert(styles, style)
          ids[key] = #styles
        end
        local last = runs[#runs]
        if last and last[1] == ids[key] then
          last[2] = last[2] .. cell[1]
        else
          table.insert(runs, { ids[key], cell[1] })
        end
      end
    end
    table.insert(rows, runs)
  end
  local lines = {
    '{',
    ('"mode": %s,'):format(vim.json.encode(screen.mode)),
    -- (as kitty draws it: where it is, its color and the text's on it)
    ('"cursor": %s,'):format(vim.json.encode({ screen.cursor[1], screen.cursor[2], KITTY.cursor, KITTY.cursor_text_color })),
    '"styles": [',
  }
  for i, style in ipairs(styles) do
    table.insert(lines, vim.json.encode(style) .. (i < #styles and ',' or ''))
  end
  vim.list_extend(lines, { '],', '"rows": [' })
  for i, runs in ipairs(rows) do
    table.insert(lines, vim.json.encode(runs) .. (i < #rows and ',' or ''))
  end
  vim.list_extend(lines, { ']', '}' })
  return table.concat(lines, '\n') .. '\n'
end

--- Captures the screen until it shows `expected` (a snapshot), or with none,
--- until it holds still for a second: what's drawn after a pause (hovers,
--- documentation, highlights) comes in its own time. Returns the screen and its
--- snapshot.
local function settle(nvim, expected)
  local function now()
    return vim.uv.hrtime() / 1e6
  end
  local deadline, last, since = now() + 10000, nil, now()
  while true do
    local screen = probe.screen(nvim, KITTY.foreground, KITTY.background)
    local shot = snapshot(screen)
    if shot ~= last then
      last, since = shot, now()
    end
    if shot == expected or not expected and now() - since >= 1000 or now() > deadline then
      return screen, shot
    end
    nvim:sleep(100)
  end
end

--- Where two snapshots differ: the rows, and the cursor
local function differences(a, b)
  local function row_texts(shot)
    return vim.tbl_map(function(runs)
      return table.concat(
        vim.tbl_map(function(run)
          return table.concat(shot.styles[run[1]], ' ') .. '\0' .. run[2]
        end, runs),
        '\0'
      )
    end, shot.rows)
  end
  local rows, ra, rb = {}, row_texts(a), row_texts(b)
  for i = 1, math.max(#ra, #rb) do
    if ra[i] ~= rb[i] then
      table.insert(rows, i)
    end
  end
  local where = #rows > 0 and ('rows ' .. table.concat(rows, ', ')) or 'no row'
  if a.mode ~= b.mode or not vim.deep_equal(a.cursor, b.cursor) then
    where = where .. ' and the cursor'
  end
  return where
end

---------------------------------------------------------------------------
-- The page
---------------------------------------------------------------------------

local function escape(s)
  return (s:gsub('[&<>"]', { ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;', ['"'] = '&quot;' }))
end

local UNDERLINE = { line = 'solid', curl = 'wavy', double = 'double', dotted = 'dotted', dashed = 'dashed' }

local function css(style)
  local fg, bg, sp, attrs, underline = unpack(style)
  local out = { 'color:' .. fg, 'background:' .. bg }
  if attrs:find('b') then
    table.insert(out, 'font-weight:bold')
  end
  if attrs:find('i') then
    table.insert(out, 'font-style:italic')
  end
  local lines = {}
  if underline ~= '' then
    table.insert(lines, 'underline')
  end
  if attrs:find('s') then
    table.insert(lines, 'line-through')
  end
  if #lines > 0 then
    table.insert(out, 'text-decoration-line:' .. table.concat(lines, ' '))
    table.insert(out, 'text-decoration-color:' .. (sp ~= '' and sp or fg))
    if underline ~= '' then
      table.insert(out, 'text-decoration-style:' .. UNDERLINE[underline])
    end
  end
  return table.concat(out, ';')
end

--- Text in HTML, each character but ASCII in a box as wide as its cells: Menlo lacks some (⏵, icons), which the
--- browser draws from another font at another width, and the rest of the row would leave the grid
local function cells(text)
  return (escape(text):gsub('[\194-\244][\128-\191]*', function(char)
    return ('<span class="c%d">%s</span>'):format(vim.fn.strdisplaywidth(char), char)
  end))
end

--- A snapshot in HTML, each run at its column, the cursor drawn as kitty does: a block, a bar in insert mode
local function screen_html(shot)
  local crow, ccol, cursor, cursor_text = unpack(shot.cursor)
  local out, columns = {}, 0
  for r, runs in ipairs(shot.rows) do
    local spans, col = {}, 1
    local function span(css_text, text)
      table.insert(spans, ('<span style="left:%dch;%s">%s</span>'):format(col - 1, css_text, cells(text)))
      col = col + vim.fn.strdisplaywidth(text)
    end
    for _, run in ipairs(runs) do
      local style, text = shot.styles[run[1]], run[2]
      if r == crow and ccol >= col and ccol < col + vim.fn.strdisplaywidth(text) then
        for _, char in ipairs(vim.fn.split(text, '\\zs')) do
          if col == ccol and shot.mode:find('^i') then
            span(css(style) .. ';box-shadow:inset 2px 0 0 ' .. cursor, char)
          elseif col == ccol then
            span(css({ cursor_text, cursor, style[3], style[4], style[5] }), char)
          else
            span(css(style), char)
          end
        end
      else
        span(css(style), text)
      end
    end
    columns = math.max(columns, col - 1)
    table.insert(out, '<div>' .. table.concat(spans) .. '</div>')
  end
  return ('<div class="screen" style="background:%s;width:%dch">%s</div>'):format(KITTY.background, columns, table.concat(out))
end

local function write_page(path, title, shown)
  local sections = {}
  for _, scene in ipairs(shown) do
    table.insert(
      sections,
      ('<section><h2>%s</h2><div class="build"><p>Build</p>%s</div><div class="old"><p>Old (snapshot)</p>%s</div></section>'):format(
        escape(scene.title),
        screen_html(scene.build),
        scene.old and screen_html(scene.old) or '<p>(none)</p>'
      )
    )
  end
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  env.write_file(
    path,
    ([[<!doctype html>
<html><head><meta charset="utf-8"><title>%s</title>
<style>
body { background: #101010; color: #bbb; font: 13px -apple-system, sans-serif; margin: 16px }
h2 { font-size: 14px; font-weight: 500; margin: 28px 0 8px }
p { margin: 4px 0; color: #888; font-size: 12px }
nav { position: sticky; top: 0; background: #101010; padding: 8px 0 }
nav button { background: #222; color: #ccc; border: 1px solid #444; border-radius: 6px; padding: 4px 10px; margin-right: 6px; cursor: pointer }
nav button.on { border-color: #9ab }
.screen { font: 12px/14px Menlo, monospace; white-space: pre; display: inline-block; padding: 6px }
.screen div { position: relative; height: 14px }
.screen div > span { position: absolute; top: 0; height: 14px }
.screen span span { display: inline-block; height: 14px; vertical-align: top }
.screen .c1, .screen .c2 { overflow: hidden }
.screen .c1 { width: 1ch }
.screen .c2 { width: 2ch }
body.build .old, body.old .build { display: none }
</style></head><body class="build">
<nav><button class="on" data-show="build">Build</button><button data-show="old">Old</button></nav>
%s
<script>
for (const b of document.querySelectorAll('nav button')) {
  b.onclick = () => {
    document.body.className = b.dataset.show
    for (const x of document.querySelectorAll('nav button')) x.classList.toggle('on', x === b)
  }
}
</script></body></html>
]]):format(escape(title), table.concat(sections, '\n'))
  )
end

---------------------------------------------------------------------------

--- A set of scenes: their snapshots in golden/scenes/`set`/, their page
--- tmp/scenes-`set`.html.
function M.set(set, title)
  local golden = ('%s/golden/scenes/%s'):format(env.tests_dir, set)
  local page = ('%s/tmp/scenes-%s.html'):format(env.tests_dir, set)
  local shown = {}
  local scenes = {}

  --- A child Neovim for scene `name`, in the directory `set`-`name`: the same
  --- in every run, as the screen may show it, and its own, as the fake servers
  --- keep their state by its name.
  function scenes.nvim(name)
    local parent = vim.fs.joinpath(env.load().run_dir, 'scenes')
    local dir = vim.fs.joinpath(parent, set .. '-' .. name)
    -- (the sets run side by side: the first of each makes the parent, whichever comes first)
    vim.uv.fs_mkdir(parent, 493)
    assert(vim.uv.fs_mkdir(dir, 493))
    return t.nvim({ cwd = dir, lines = 40, columns = 112 })
  end

  --- Compares the screen with scene `name`'s snapshot, golden/scenes/`set`/`name`.json, and shows both on the page.
  function scenes.check(nvim, name, scene_title)
    local path = ('%s/%s.json'):format(golden, name)
    local old = env.read_file(path)
    local expected = not UPDATE and old or nil
    local screen, actual = settle(nvim, expected)
    t.eq(0, screen.unfound, 'every float found on the screen')
    table.insert(shown, { title = scene_title, build = vim.json.decode(actual), old = old and vim.json.decode(old) })
    write_page(page, title, shown)
    if not expected then
      vim.fn.mkdir(golden, 'p')
      env.write_file(path, actual)
      t.ok(UPDATE, ('golden/scenes/%s/%s.json created (re-run to compare)'):format(set, name))
      return
    end
    t.ok(
      actual == expected,
      ('the screen differs from golden/scenes/%s/%s.json in %s: compare them in %s, then take it with `run --update-golden scenes`'):format(
        set,
        name,
        differences(vim.json.decode(actual), vim.json.decode(expected)),
        page
      )
    )
  end

  return scenes
end

return M
