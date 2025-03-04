local M = {}

local constants = require("waypoint.constants")
local state = require("waypoint.state")
local utils = require("waypoint.utils")

local bufnr

local function set_modifiable(is_modifiable)
  vim.bo[bufnr].modifiable = is_modifiable
  vim.bo[bufnr].readonly = not is_modifiable
end

-- Function to indent or unindent the current line by 2 spaces
-- if doIndent is true, indent. otherwise unindent
function IndentLine(doIndent)
  set_modifiable(true)
  local line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (1-based)
  local line = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1]

  if line then
    local changed_line
    if doIndent then
      changed_line = "  " .. line -- Prepend two spaces
    else
      changed_line = line:gsub("^  ", "", 1)
    end
    vim.api.nvim_buf_set_lines(bufnr, line_nr - 1, line_nr, false, { changed_line })
  end
  vim.bo[bufnr].modifiable = false
  set_modifiable(false)
end

function MoveLineUp()
  local line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number
  if line_nr == 1 then return end -- Don't move if it's the first line

  -- Get current and previous lines
  local new_lines = vim.api.nvim_buf_get_lines(bufnr, line_nr - 2, line_nr, false)
  if #new_lines < 2 then return end -- Edge case: if somehow the range is invalid

  set_modifiable(true)
  -- Swap lines
  vim.api.nvim_buf_set_lines(bufnr, line_nr - 2, line_nr, false, { new_lines[2], new_lines[1] })

  -- Move cursor up to keep it on the moved line
  vim.api.nvim_win_set_cursor(0, { line_nr - 1, 0 })

  set_modifiable(false)
end

function MoveLineDown()
  local line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number
  local last_line = vim.api.nvim_buf_line_count(0)
  if line_nr == last_line then return end -- Don't move if it's the last line

  -- Get current and next lines
  local lines = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr + 1, false)
  print(#lines)
  if #lines < 2 then return end -- Edge case: if somehow the range is invalid

  set_modifiable(true)
  -- Swap lines
  vim.api.nvim_buf_set_lines(bufnr, line_nr - 1, line_nr + 1, false, { lines[2], lines[1] })

  -- Move cursor up to keep it on the moved line
  vim.api.nvim_win_set_cursor(0, { line_nr + 1, 0 })

  set_modifiable(false)
end

function M.open()
  local is_listed = false
  local is_scratch = false

  --- @type integer
  bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)
  local bg_bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)

  vim.bo[bufnr].buftype = "nofile"  -- Prevents the buffer from being treated as a normal file
  vim.bo[bufnr].bufhidden = "wipe"  -- Ensures the buffer is removed when closed
  vim.bo[bufnr].swapfile = false    -- Prevents swap file creation

  local lines = {}

  for _, waypoint in pairs(state.window.waypoints) do
    local line = waypoint.filepath .. " | " .. tostring(waypoint.line_nr) .. " | " .. waypoint.annotation
    -- table.insert(lines, path .. tostring(line_nr))
    -- table.insert(lines, waypoint.annotation)
    -- table.insert(lines, "")
    table.insert(lines, line)
  end

  -- Set some text in the buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  do -- highlights
    -- Define highlight group
    vim.cmd("highlight MyCursorHighlight guibg=DarkGray guifg=White")

    -- Create a highlight namespace
    local ns_id = vim.api.nvim_create_namespace("cursor_highlight")

    -- Function to highlight the current line
    local function highlight_cursor_line()
      -- Clear previous highlights
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

      -- Get cursor position
      local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1  -- Convert to 0-indexed

      -- Apply highlight to the current line
      vim.api.nvim_buf_add_highlight(bufnr, ns_id, "MyCursorHighlight", cursor_line, 0, -1)
    end

    -- Set up an autocmd to trigger on cursor movement
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = constants.augroup,
      buffer = bufnr,
      callback = highlight_cursor_line,
    })

    -- Initialize highlight on first load
    highlight_cursor_line()

    vim.api.nvim_create_autocmd("BufLeave", {
      group = constants.augroup,
      buffer = bufnr,
      callback = function()
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
      end,
    })
  end


  -- change the buffer content to be fixed
  vim.bo[bufnr].modifiable = false  -- Disables editing the buffer
  vim.bo[bufnr].readonly = true     -- Marks it as read-only

  -- Get editor width and height
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines") - 2

  -- Calculate floating window size
  local win_width = math.ceil(width * constants.float_width)
  local win_height = math.ceil(height * constants.float_height)

  -- Calculate starting position
  local row = math.ceil((height - win_height) / 2)
  local col = math.ceil((width - win_width) / 2)


  -- Set window options
  local opts = {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
  }
  local bg_win_opts = utils.shallow_copy(opts)

  print(vim.inspect(opts))

  -- Create the background
  -- Create the window
  local hpadding = 3
  local vpadding = 2
  bg_win_opts.row = opts.row - vpadding
  bg_win_opts.col = opts.col - hpadding
  bg_win_opts.width = opts.width + hpadding * 2
  bg_win_opts.height = opts.height + vpadding * 2
  bg_win_opts.border = "rounded"
  bg_win_opts.title = "Waypoints"
  bg_win_opts.title_pos = "center"
  local bg_winnr = vim.api.nvim_open_win(bg_bufnr, true, bg_win_opts)
  local winnr = vim.api.nvim_open_win(bufnr, true, opts)

  function CloseFloat()
    vim.api.nvim_win_close(bg_winnr, true)
    vim.api.nvim_win_close(winnr, true)
  end

  function GotoWaypoint()
    CloseFloat()
    local cur_waypoint = state.window.waypoints[state.window.current_waypoint or 1]
    local bufnr = vim.fn.bufnr(cur_waypoint.filepath)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_win_set_cursor(0, {cur_waypoint.line_nr, 0})
  end

  -- Add a mapping to close the window
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q',     ':lua CloseFloat()<CR>', {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<esc>', ':lua CloseFloat()<CR>', {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(bufnr, "n", ">", ":lua IndentLine(true)<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "l", ":lua IndentLine(true)<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<", ":lua IndentLine(false)<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "h", ":lua IndentLine(false)<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "K", ":lua MoveLineUp()<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "J", ":lua MoveLineDown()<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", ":lua GotoWaypoint()<CR>", { noremap = true, silent = true })

  -- other keybinds
  -- o to createw blank line below
  -- O to createw blank line above
  -- dd to delete line
  -- u     to undo
  -- <c-r> to redo
  -- C     to increase the size of the total context window
  -- c     to decrease context
  -- A     to increase after context
  -- a     to decrease after context
  -- B     to increase before context
  -- b     to decrease before context
  -- t     to add a title
  -- T     to remove a title
  --
  -- visual mode delete to delete groups of lines
  -- making new groups (tabs)
  -- navigating between groups
  -- combining groups
  -- change the title of a group
  --  inspo: zellij
  -- move line to group
  -- make a command :Waypoint to bring up the waypoint window
  -- show undo stack
  --   move waypoint x to group y
  --   combined group x with group y
  -- store bookmarks in the folder you have open in vim
  -- 
  -- telescope extension to search by either title or line contents
  -- list waypoints in the quickfix list
  -- should be able to open a floating window, a window on the left (like nvim tree), or a window on the right
  -- have the ability to list by custom order or by mru
  --
  -- cols in table
  -- line/col
  -- text at line/col
  -- bookmark
end

return M
