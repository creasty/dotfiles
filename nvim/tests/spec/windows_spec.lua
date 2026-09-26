local t = require('t')
local describe, it = t.describe, t.it

local function tab_count(nvim)
  return #nvim:request('nvim_list_tabpages')
end

local function tab_index(nvim)
  return nvim:call('tabpagenr')
end

local function normal_windows(nvim)
  return nvim:lua([[
    local wins = {}
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(w).relative == '' then
        local pos = vim.api.nvim_win_get_position(w)
        wins[#wins + 1] = {
          win = w,
          name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)), ':t'),
          row = pos[1], col = pos[2],
          height = vim.api.nvim_win_get_height(w), width = vim.api.nvim_win_get_width(w),
          current = w == vim.api.nvim_get_current_win(),
        }
      end
    end
    return wins
  ]])
end

local function current_window(nvim)
  for _, w in ipairs(normal_windows(nvim)) do
    if w.current then
      return w
    end
  end
end

describe('Windows and tabs (<C-s> is <C-w>)', function()
  it('<C-s>t opens a new tab, <C-s>n / <C-s>b go to the next / previous tab', function()
    local nvim = t.nvim()
    nvim:type('<C-s>t')
    nvim:type('<C-s><C-t>')
    t.eq(3, tab_count(nvim))
    t.eq(3, tab_index(nvim))
    nvim:type('<C-s>b')
    t.eq(2, tab_index(nvim))
    nvim:type('<C-s><C-b>')
    t.eq(1, tab_index(nvim))
    nvim:type('<C-s>n')
    t.eq(2, tab_index(nvim))
    nvim:type('<C-s><C-n>')
    t.eq(3, tab_index(nvim))
  end)

  it('<C-s>v opens an empty window on the right', function()
    local nvim = t.nvim()
    nvim:edit('a.txt', { 'a' })
    nvim:type('<C-s>v')
    local wins = normal_windows(nvim)
    t.eq(2, #wins)
    local cur = current_window(nvim)
    t.eq('', cur.name, 'new window holds an empty buffer')
    t.ok(cur.col > 0, 'new window is on the right')
    t.eq({ '' }, nvim:lines())
    nvim:type('<C-s><C-v>')
    t.eq(3, #normal_windows(nvim))
  end)

  it('<C-s>s opens an empty window below', function()
    local nvim = t.nvim()
    nvim:edit('a.txt', { 'a' })
    nvim:type('<C-s>s')
    t.eq(2, #normal_windows(nvim))
    local cur = current_window(nvim)
    t.eq('', cur.name)
    t.ok(cur.row > 1, 'new window is below')
    nvim:type('<C-s><C-s>')
    t.eq(3, #normal_windows(nvim))
  end)

  it('<C-s>d closes the current window', function()
    local nvim = t.nvim()
    nvim:type('<C-s>v<C-s>v')
    t.eq(3, #normal_windows(nvim))
    nvim:type('<C-s>d')
    t.eq(2, #normal_windows(nvim))
    nvim:type('<C-s><C-d>')
    t.eq(1, #normal_windows(nvim))
  end)

  it('<C-s>c is disabled (does not close the window)', function()
    local nvim = t.nvim()
    nvim:type('<C-s>v')
    nvim:type('<C-s>c')
    nvim:type('<C-s><C-c>')
    t.eq(2, #normal_windows(nvim))
  end)

  it('<C-s>h / <C-s>l move between windows', function()
    local nvim = t.nvim()
    nvim:edit('a.txt', { 'a' })
    nvim:type('<C-s>v')
    nvim:type('<C-s>h')
    t.eq('a.txt', current_window(nvim).name)
    nvim:type('<C-s>l')
    t.eq('', current_window(nvim).name)
  end)

  it('<C-s>+ / - / > / < resize and keep resizing while you repeat the last key', function()
    local nvim = t.nvim()
    nvim:type('<C-s>s')
    local before = current_window(nvim).height
    nvim:type('<C-s>+++')
    t.eq(before + 3, current_window(nvim).height)
    nvim:type('<C-s>--')
    t.eq(before + 1, current_window(nvim).height)
    nvim:type('<C-s>v')
    local width = current_window(nvim).width
    nvim:type('<C-s>>>')
    t.eq(width + 2, current_window(nvim).width)
    nvim:type('<C-s><lt><lt><lt>')
    t.eq(width - 1, current_window(nvim).width)
  end)

  it('<C-s>r brings back the buffer of a window you just closed', function()
    local nvim = t.nvim()
    nvim:files({ ['a.txt'] = { 'a' }, ['b.txt'] = { 'b' } })
    nvim:edit('a.txt')
    nvim:cmd('vsplit b.txt')
    nvim:type('<C-s>d')
    t.eq('a.txt', nvim:call('expand', '%:t'))
    nvim:type('<C-s>r')
    t.eq('b.txt', nvim:call('expand', '%:t'))
    t.eq(1, #normal_windows(nvim), 'reopens in the current window')
  end)

  it('<C-s><C-r> brings back the previously edited buffer', function()
    local nvim = t.nvim()
    nvim:files({ ['a.txt'] = { 'a' }, ['b.txt'] = { 'b' } })
    nvim:edit('a.txt')
    nvim:edit('b.txt')
    nvim:type('<C-s><C-r>')
    t.eq('a.txt', nvim:call('expand', '%:t'))
  end)
end)
