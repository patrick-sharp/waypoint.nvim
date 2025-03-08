local M = {}

local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")


local prev_window_handle
local bufnr
local winnr
local bg_winnr


local function set_modifiable(is_modifiable)
  if bufnr == nil then error("Should not be called before initializing window") end
  vim.bo[bufnr].modifiable = is_modifiable
  vim.bo[bufnr].readonly = not is_modifiable
end


local function draw(center)
  set_modifiable(true)
  vim.api.nvim_buf_clear_namespace(bufnr, constants.ns, 0, -1)
  local rows = {}
  local indents = {}

  local cursor_line
  local waypoint_topline
  local waypoint_bottomline

  local highlight_start
  local highlight_end

  -- note that this fucks up with unicode
  local annotation_width = 0
  for _, waypoint in ipairs(state.waypoints) do
    if waypoint.annotation then
      annotation_width = math.max(annotation_width, #waypoint.annotation)
    end
  end

  for i, waypoint in ipairs(state.waypoints) do
    local _, extmark_lines, extmark_line_0i, context_start_line_nr_0i = u.extmark_lines_for_waypoint(waypoint)
    assert(extmark_lines)

    if i == state.wpi then
      highlight_start = #rows
      waypoint_topline = #rows
      waypoint_bottomline = #rows + #extmark_lines
      cursor_line = #rows + extmark_line_0i
    end

    for j, line_text in ipairs(extmark_lines) do
      table.insert(indents, waypoint.indent)
      local row = {}

      -- marker for where the waypoint actually is within the context
      if j == extmark_line_0i + 1 then
        table.insert(row, "*")
      else
        table.insert(row, "")
      end

      -- annotation
      if state.show_annotation then
        if j == extmark_line_0i + 1 and waypoint.annotation then
          table.insert(row, waypoint.annotation)
        else
          table.insert(row, "")
        end
      end

      -- path
      if state.show_path then
        if state.show_full_path then
          table.insert(row, waypoint.filepath)
        else
          local filename = vim.fn.fnamemodify(waypoint.filepath, ":t")
          table.insert(row, filename)
        end
      end

      -- line number
      if state.show_line_num then
        table.insert(row, tostring(context_start_line_nr_0i + j))
      end

      -- file text
      if state.show_file_text then
        table.insert(row, line_text)
      end

      for _,v in pairs(row) do
        if v == nil then
          u.p(row)
        end
      end

      table.insert(rows, row)
    end
    if i == state.wpi then
      highlight_end = #rows
    end
    if #extmark_lines > 1 and i < #state.waypoints then
      table.insert(rows, "")
      table.insert(indents, 0)
    end
  end

  local aligned = u.align_table(rows)

  for i, line in pairs(aligned) do
    aligned[i] = string.rep("  ", indents[i]) .. line
  end

  -- Set some text in the buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, aligned)

  -- Define highlight group
  --local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1  -- Convert to 0-indexed
  if state.wpi and highlight_start and highlight_end and cursor_line then
    vim.api.nvim_win_set_cursor(0, { cursor_line + 1, 0 })
    local view = vim.fn.winsaveview()
    view.leftcol = state.scroll_col
    view.coladd = state.scroll_col
    view.col = state.scroll_col
    local topline = view.topline

    local height = vim.api.nvim_get_option("lines") - 2
    local win_height = math.ceil(height * constants.float_height)

    if waypoint_topline < topline then
      -- u.p("TOPP", topline, topline + win_height, waypoint_topline, waypoint_bottomline)
      view.topline = waypoint_topline
    elseif topline + win_height < waypoint_bottomline then
      -- u.p("BOTT", topline, topline + win_height, waypoint_topline, waypoint_bottomline)
      view.topline = waypoint_bottomline - win_height
    else
      -- u.p("NONE", topline, topline + win_height, waypoint_topline, waypoint_bottomline)
    end
    vim.fn.winrestview(view)
    vim.cmd("highlight " .. constants.hl_selected .. " guibg=DarkGray guifg=White")
    for i=highlight_start,highlight_end-1 do
      vim.api.nvim_buf_add_highlight(bufnr, constants.ns, constants.hl_selected, i, 0, -1)
    end

  end
  set_modifiable(false)
  if center then
    vim.api.nvim_command("normal! zz")
  end
end



-- Function to indent or unindent the current line by 2 spaces
-- if doIndent is true, indent. otherwise unindent
function IndentLine(do_indent)
  if state.wpi == nil then return end
  local indent = state.waypoints[state.wpi].indent
  if do_indent then
    indent = indent + 1
  else
    indent = indent - 1
  end
  state.waypoints[state.wpi].indent = u.clamp(indent, 0, 20)
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
  state.wpi = u.clamp(
    state.wpi + 1,
    1,
    #state.waypoints
  )
  draw()
end



function PrevWaypoint()
  if state.wpi == nil then return end
  state.wpi = u.clamp(
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
  local extmark = u.extmark_for_waypoint(waypoint)

  local waypoint_bufnr = vim.fn.bufnr(waypoint.filepath)
  vim.api.nvim_win_set_buf(0, waypoint_bufnr)
  vim.api.nvim_win_set_cursor(0, { extmark[1] + 1, 0 })
end


function IncreaseContext(increment)
  state.context = u.clamp(state.context + increment, 0)
  draw(true)
end


function IncreaseBeforeContext(increment)
  state.before_context = u.clamp(state.before_context + increment, 0)
  draw(true)
end


function IncreaseAfterContext(increment)
  state.after_context = u.clamp(state.after_context + increment, 0)
  draw(true)
end


function ResetContext()
  state.context = 0
  state.before_context = 0
  state.after_context = 0
  draw()
end


function Scroll(increment)
  state.scroll_col = u.clamp(state.scroll_col + increment, 0, 999)
  draw()
end


function ResetScroll()
  state.scroll_col = 0
  draw()
end


function ToggleAnnotation()
  state.show_annotation = not state.show_annotation
  draw()
end

function TogglePath()
  state.show_path = not state.show_path
  draw()
end

function ToggleFullPath()
  state.show_full_path = not state.show_full_path
  draw()
end

function ToggleLineNum()
  state.show_line_num = not state.show_line_num
  draw()
end

function ToggleFileText()
  state.show_file_text = not state.show_file_text
  draw()
end


function M.open()
  prev_window_handle = vim.api.nvim_get_current_win()
  if state.wpi == nil and #state.waypoints > 0 then
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
  local bg_win_opts = u.shallow_copy(opts)

  local hpadding = 3
  local vpadding = 1
  bg_win_opts.row = opts.row - vpadding - 1
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

  local function keymap_opts()
    return {
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q',     ":lua Close()<CR>",                   keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<esc>', ":lua Close()<CR>",                   keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", ">",     ":lua IndentLine(true)<CR>",          keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<",     ":lua IndentLine(false)<CR>",         keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "l",     ":lua Scroll(4)<CR>",                 keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "h",     ":lua Scroll(-4)<CR>",                keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "0",     ":lua ResetScroll()<CR>",            keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "j",     ":lua NextWaypoint()<CR>",            keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "k",     ":lua PrevWaypoint()<CR>",            keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "K",     ":lua MoveWaypointUp()<CR>",          keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "J",     ":lua MoveWaypointDown()<CR>",        keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>",  ":lua GoToWaypoint()<CR>",            keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "C",     ":lua IncreaseContext(1)<CR>",        keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "c",     ":lua IncreaseContext(-1)<CR>",       keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "B",     ":lua IncreaseBeforeContext(1)<CR>",  keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "b",     ":lua IncreaseBeforeContext(-1)<CR>", keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "A",     ":lua IncreaseAfterContext(1)<CR>",   keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "a",     ":lua IncreaseAfterContext(-1)<CR>",  keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "r",     ":lua ResetContext()<CR>",            keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "o",     ":lua ToggleAnnotation()<CR>",        keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "p",     ":lua TogglePath()<CR>",              keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "f",     ":lua ToggleFullPath()<CR>",          keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "n",     ":lua ToggleLineNum()<CR>",           keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "t",     ":lua ToggleFileText()<CR>",          keymap_opts())

  -- done keybinds
  -- C     to increase the size of the total context window
  -- c     to decrease context
  -- A     to increase after context
  -- a     to decrease after context
  -- B     to increase before context
  -- b     to decrease before context
  --
  -- todo keybinds
  -- dd to delete line
  -- u     to undo
  -- <c-r> to redo
  -- t     to add a title
  -- T     to remove a title
  -- f     to toggle full file paths
  --
  --
  -- visual mode delete to delete groups of lines
  -- visual mode + J/K to move groups of waypoints
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
  --
  -- other ideas:
  -- if a waypoint has a waypoint under it that has more indentation, then put a
  --   blank line between last waypoint under it with less indentation and the 
  --   next waypoint with equal indentation
  -- show everything in a column aligned table. leftmost column can be filename + indentation
  -- syntax highlight the partss that come from actual files
  -- figure out how to more gracefully make sure the window open state never gets weird.
  -- make saving and loading waypoints to file automatic
  -- if the cursor movement wouldn't make all of a waypoint visible, try to move the screen so it's all visible

end

function Close()
  vim.api.nvim_win_close(bg_winnr, true)
  vim.api.nvim_win_close(winnr, true)
  vim.api.nvim_set_current_win(prev_window_handle)
end

return M
