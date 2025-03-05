local M = {}

local constants = require("waypoint.constants")
local state = require("waypoint.state")
local utils = require("waypoint.utils")


local prev_window_handle
local bufnr
local winnr
local bg_winnr


local function set_modifiable(is_modifiable)
  if bufnr == nil then error("Should not be called before initializing window") end
  vim.bo[bufnr].modifiable = is_modifiable
  vim.bo[bufnr].readonly = not is_modifiable
end


local function draw()
  set_modifiable(true)
  vim.api.nvim_buf_clear_namespace(bufnr, constants.ns, 0, -1)
  local lines = {}

  for _, waypoint in pairs(state.waypoints) do
    local extmark = utils.extmark_for_waypoint(waypoint)
    local line_parts = {}
    for _=1,waypoint.indent do
      table.insert(line_parts, "  ")
    end
    table.insert(line_parts, waypoint.filepath)
    table.insert(line_parts, " | ")
    table.insert(line_parts, tostring(extmark[1] + 1))
    table.insert(line_parts, " | ")
    table.insert(line_parts, waypoint.annotation)
    table.insert(line_parts, " | ")
    local _, line_text = utils.extmark_line_for_waypoint(waypoint)
    table.insert(line_parts, line_text)

    local line = table.concat(line_parts, "")
    table.insert(lines, line)
  end

  -- Set some text in the buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  -- Define highlight group
  --local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1  -- Convert to 0-indexed
  if state.wpi then
    vim.api.nvim_win_set_cursor(0, { state.wpi, 0 })
    vim.cmd("highlight " .. constants.hl_selected .. " guibg=DarkGray guifg=White")
    vim.api.nvim_buf_add_highlight(bufnr, constants.ns, constants.hl_selected, state.wpi - 1, 0, -1)
  end
  set_modifiable(false)
end



-- Function to indent or unindent the current line by 2 spaces
-- if doIndent is true, indent. otherwise unindent
function IndentLine(do_indent)
  local indent = state.waypoints[state.wpi].indent
  if do_indent then
    indent = indent + 1
  else
    indent = indent - 1
  end
  state.waypoints[state.wpi].indent = utils.clamp(indent, 0, 20)
  draw()
end



function MoveWaypointUp()
  if #state.waypoints <= 1 or (state.wpi == 1) then return end
  local temp = state.waypoints[state.wpi - 1]
  state.waypoints[state.wpi - 1] = state.waypoints[state.wpi]
  state.waypoints[state.wpi] = temp
  state.wpi = state.wpi - 1
  draw()
end



function MoveWaypointDown()
  if #state.waypoints <= 1 or (state.wpi == #state.waypoints) then return end
  local temp = state.waypoints[state.wpi + 1]
  state.waypoints[state.wpi + 1] = state.waypoints[state.wpi]
  state.waypoints[state.wpi] = temp
  state.wpi = state.wpi + 1
  draw()
end



function NextWaypoint()
  if state.wpi == nil then return end
  state.wpi = utils.clamp(
    state.wpi + 1,
    1,
    #state.waypoints
  )
  draw()
end



function PrevWaypoint()
  if state.wpi == nil then return end
  state.wpi = utils.clamp(
    state.wpi - 1,
    1,
    #state.waypoints
  )
  draw()
end



function GoToWaypoint()
  if state.wpi == nil then return end

  Close()
  --- @type Waypoint | nil 
  local waypoint = state.waypoints[state.wpi]
  if waypoint == nil then vim.api.nvim_err_writeln("waypoint should not be nil") return end
  local extmark = utils.extmark_for_waypoint(waypoint)

  local waypoint_bufnr = vim.fn.bufnr(waypoint.filepath)
  vim.api.nvim_set_current_win(prev_window_handle)
  vim.api.nvim_win_set_buf(0, waypoint_bufnr)
  vim.api.nvim_win_set_cursor(0, { extmark[1] + 1, 0 })
end



function M.open()
  prev_window_handle = vim.api.nvim_get_current_win()
  if state.wpi == nil then
    state.wpi = 1
  end
  local is_listed = false
  local is_scratch = false

  --- @type integer
  bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)
  local bg_bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)

  vim.bo[bufnr].buftype = "nofile"  -- Prevents the buffer from being treated as a normal file
  vim.bo[bufnr].bufhidden = "wipe"  -- Ensures the buffer is removed when closed
  vim.bo[bufnr].swapfile = false    -- Prevents swap file creation

  vim.api.nvim_create_autocmd("BufLeave", {
    group = constants.augroup,
    buffer = bufnr,
    callback = function()
      vim.api.nvim_buf_clear_namespace(bufnr, constants.ns, 0, -1)
    end,
  })

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

  local hpadding = 3
  local vpadding = 2
  bg_win_opts.row = opts.row - vpadding
  bg_win_opts.col = opts.col - hpadding
  bg_win_opts.width = opts.width + hpadding * 2
  bg_win_opts.height = opts.height + vpadding * 2
  bg_win_opts.border = "rounded"
  bg_win_opts.title = "Waypoints"
  bg_win_opts.title_pos = "center"

  -- Create the background
  bg_winnr = vim.api.nvim_open_win(bg_bufnr, true, bg_win_opts)
  -- Create the window
  winnr = vim.api.nvim_open_win(bufnr, true, opts)

  draw()

  -- Add a mapping to close the window
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q',     ':lua Close()<CR>', {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<esc>', ':lua Close()<CR>', {noremap = true, silent = true})

  vim.api.nvim_buf_set_keymap(bufnr, "n", ">", ":lua IndentLine(true)<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "l", ":lua IndentLine(true)<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<", ":lua IndentLine(false)<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "h", ":lua IndentLine(false)<CR>", { noremap = true, silent = true })

  vim.api.nvim_buf_set_keymap(bufnr, "n", "j", ":lua NextWaypoint()<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "k", ":lua PrevWaypoint()<CR>", { noremap = true, silent = true })

  vim.api.nvim_buf_set_keymap(bufnr, "n", "K", ":lua MoveWaypointUp()<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "J", ":lua MoveWaypointDown()<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", ":lua GoToWaypoint()<CR>", { noremap = true, silent = true })

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

function Close()
  vim.api.nvim_win_close(bg_winnr, true)
  vim.api.nvim_win_close(winnr, true)
end

return M
