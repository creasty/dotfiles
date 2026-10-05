-- macOS's keyboard layout (ABC) whenever Neovim is in Normal mode, as an input
-- method (Japanese) would take its keys: on entering Normal mode, however it
-- is entered, and on starting or gaining focus in it, as another app or a
-- terminal may have left an input method on.

local M = {}

--- Selects the ASCII-capable keyboard layout used last (ABC), which does
--- nothing when it is selected, and returns TISSelectInputSource's status. It
--- runs on a worker thread, in a Lua state of its own.
local function select_layout()
  local ffi = require('ffi')
  ffi.cdef([[
    typedef struct __TISInputSource *TISInputSourceRef;
    TISInputSourceRef TISCopyCurrentASCIICapableKeyboardLayoutInputSource(void);
    int32_t TISSelectInputSource(TISInputSourceRef inputSource);
    void CFRelease(const void *cf);
  ]])
  local carbon = ffi.load('/System/Library/Frameworks/Carbon.framework/Carbon')
  local layout = carbon.TISCopyCurrentASCIICapableKeyboardLayoutInputSource()
  if layout == nil then
    return
  end
  local status = carbon.TISSelectInputSource(layout)
  ffi.C.CFRelease(layout)
  return tonumber(status)
end

local waiting -- the callbacks of the selection running, nil while none runs

local work = vim.uv.new_work(select_layout, function(status)
  local callbacks = waiting
  waiting = nil
  for _, callback in ipairs(callbacks) do
    callback(status)
  end
end)

--- Selects the layout on a worker thread, then calls `callback` with the
--- status (0 once selected, nil on an error). The first selection in a process
--- takes about 50 ms, the next ones a few. macOS's input sources take calls
--- from one thread at a time (TextInputSources.h): asked for while one runs,
--- a selection only waits for it, as that one selects the same layout.
function M.select_layout(callback)
  if not waiting then
    waiting = {}
    work:queue()
  end
  table.insert(waiting, callback)
end

--- Normal mode, in a buffer (n) or a terminal's (nt): not Insert mode's <C-o>
--- (niI), nor an operator's (no).
local function in_normal_mode()
  local mode = vim.api.nvim_get_mode().mode
  return mode == 'n' or mode == 'nt'
end

local function check()
  -- Only with a UI, which gets its keys through macOS's input sources: not for
  -- scripts and tests, running headless, nor with $NVIM_KEEP_INPUT_SOURCE set
  -- (tests with a terminal UI)
  if in_normal_mode() and #vim.api.nvim_list_uis() > 0 and not vim.env.NVIM_KEEP_INPUT_SOURCE then
    M.select_layout()
  end
end

function M.setup()
  if vim.fn.has('mac') == 0 then
    return
  end
  vim.api.nvim_create_autocmd({ 'ModeChanged', 'FocusGained', 'UIEnter' }, {
    group = vim.api.nvim_create_augroup('user.input_source', {}),
    -- Once Neovim is idle: a mapping that passes through Normal mode back to
    -- Insert mode (<Esc>...a) stays in the input method
    callback = function()
      vim.schedule(check)
    end,
  })
end

return M
