local M = {}

local config = require("waypoint.config")
local crud = require("waypoint.crud")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")


local bufnr
local winnr
local bg_winnr
-- if the user does something to move the cursor to another line, we want to set
-- the new selected waypoint to whatever waypoint the cursor is currently on
local line_to_waypoint
local longest_line_len

-- I use this to avoid drawing twice when the cursor moves.
-- I have no idea how nvim orders events and event handlers so hopefully this 
-- isn't a catastrophe waiting to happen
local ignore_next_cursormoved

local draws = 0


local function set_modifiable(is_modifiable)
  if bufnr == nil then error("Should not be called before initializing window") end
  vim.bo[bufnr].modifiable = is_modifiable
  vim.bo[bufnr].readonly = not is_modifiable
end


local function get_total_width()
  return vim.api.nvim_get_option("columns")
end

local function get_total_height()
  local height = vim.api.nvim_get_option("lines")
  height = height - vim.o.cmdheight
  height = height - vim.o.laststatus
  return height
end

local function get_floating_window_width()
  return math.ceil(get_total_width() * config.window_width)
end

local function get_floating_window_height()
  return math.ceil(get_total_height() * config.window_height)
end

local function get_win_opts()
  -- Get editor width and height
  local width = get_total_width()
  local height = get_total_height()

  -- Calculate floating window size
  local win_width = get_floating_window_width()
  local win_height = get_floating_window_height()

  -- Calculate starting position
  local row = math.ceil((height - win_height) / 2)
  local col = math.ceil((width - win_width) / 2)
  local win_opts = {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
  }
  return win_opts
end

local function get_bg_win_opts(win_opts)
  assert(win_opts, "win_opts required arg to get_bg_win_opts")
  local bg_win_opts = u.shallow_copy(win_opts)

  local hpadding = 2
  local vpadding = 1
  bg_win_opts.row = win_opts.row - vpadding - 1
  bg_win_opts.col = win_opts.col - hpadding - 1
  bg_win_opts.width = win_opts.width + hpadding * 2
  bg_win_opts.height = win_opts.height + vpadding * 2
  bg_win_opts.border = "rounded"
  bg_win_opts.title = "Waypoints"
  -- todo: make the background of this equal to window background
  local a = {"   A: " .. state.after_context, constants.hl_footer_after_context }
  local b = {"   B: " .. state.before_context, constants.hl_footer_before_context }
  local c = {"   C: " .. state.context, constants.hl_footer_context }
  bg_win_opts.footer = {{"Press g? for help", constants.hl_selected}, a, b, c }
  bg_win_opts.title_pos = "center"
  return bg_win_opts
end


local function draw(action)
  draws = draws + 1
  if action == nil then
    -- print("DRAW" .. draws .. " nil")
  else
    -- print("DRAW" .. draws .. " " .. action)
  end
  set_modifiable(true)
  vim.api.nvim_buf_clear_namespace(bufnr, constants.ns, 0, -1)
  local rows = {}
  local indents = {}
  line_to_waypoint = {}

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
      waypoint_topline = #rows + 1
      waypoint_bottomline = #rows + #extmark_lines
      cursor_line = #rows + extmark_line_0i
    end


    -- TODO: highlight filenames properly
    local hl_name = "Directory"  -- Change this if needed
    local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false }) 

    for j, line_text in ipairs(extmark_lines) do
      table.insert(indents, waypoint.indent)
      table.insert(line_to_waypoint, i)
      local row = {}

      -- marker for where the waypoint actually is within the context
      if j == extmark_line_0i + 1 then
        table.insert(row, tostring(i))
        table.insert(row, "*")
      else
        table.insert(row, "")
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
    local has_context = state.before_context ~= 0
    has_context = has_context or state.context ~= 0
    has_context = has_context or state.after_context ~= 0
    if has_context  and i < #state.waypoints then
      table.insert(rows, "")
      table.insert(indents, 0)
      -- if the user somehow moves to a blank space, just treat that as 
      -- selecting the waypoint above the space
      table.insert(line_to_waypoint, i)
    end
  end

  assert(#rows == #indents, "#rows == " .. #rows ..", #indents == " .. #indents .. ", but they should be the same" )
  assert(#rows == #line_to_waypoint, "#rows == " .. #rows ..", #line_to_waypoint == " .. #line_to_waypoint .. ", but they should be the same" )

  local table_cell_types = {"number", "string"}
  if state.show_annotation then
    table.insert(table_cell_types, "string")
  end
  if state.show_path then
    table.insert(table_cell_types, "string")
  end
  if state.show_line_num then
    table.insert(table_cell_types, "number")
  end
  if state.show_file_text then
    table.insert(table_cell_types, "string")
  end
  local aligned = u.align_table(rows, table_cell_types)


  longest_line_len = 0
  for i, line in pairs(aligned) do
    aligned[i] = string.rep(" ", indents[i]) .. line
    longest_line_len = math.max(longest_line_len, #aligned[i])
  end

  -- Set text in the buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, aligned)

  -- Define highlight group
  if state.wpi and highlight_start and highlight_end and cursor_line then
    if action == "move_to_waypoint" or action == "context" then
      vim.api.nvim_win_set_cursor(0, { cursor_line + 1, 0 })
    end

    local view = vim.fn.winsaveview()

    local topline = view.topline

    local win_height = get_floating_window_height()

    if waypoint_topline < topline then
      -- u.p("TOPP", topline, topline + win_height, waypoint_topline, waypoint_bottomline)
      view.topline = waypoint_topline
    elseif topline + win_height < waypoint_bottomline then
      -- u.p("BOTT", topline, topline + win_height, waypoint_topline, waypoint_bottomline)
      view.topline = waypoint_bottomline - win_height
    else
      -- u.p("NONE", "CL", cursor_line, topline, topline + win_height, "WP", waypoint_topline, waypoint_bottomline)
      -- u.p("NONE", view)
    end
    if action == "scroll" then
      view.leftcol = state.scroll_col
      -- for some reason vim.fn.restview doesn't do what it's supposed if the leftcol and col are the same
      -- so I have to do this, and then adjust the col to the left side of the screen afterward
      view.col = view.leftcol + 20
      vim.fn.winrestview(view)
      vim.cmd("normal! " .. state.scroll_col .. "|")
    end

    vim.cmd("highlight " .. constants.hl_selected .. " guibg=DarkGray guifg=White")
    for i=highlight_start,highlight_end-1 do
      vim.api.nvim_buf_add_highlight(bufnr, constants.ns, constants.hl_selected, i, 0, -1)
    end

  end

  local win_opts = get_win_opts()
  local bg_win_opts = get_bg_win_opts(win_opts)
  vim.api.nvim_win_set_config(winnr, win_opts)
  vim.api.nvim_win_set_config(bg_winnr, bg_win_opts)

  set_modifiable(false)
  if action == "center" or action == "context" then
    vim.api.nvim_command("normal! zz")
  end
  if action ~= "set_waypoint_for_cursor" then
    ignore_next_cursormoved = true
  end
end



-- Function to indent or unindent the current line by 2 spaces
-- if doIndent is true, indent. otherwise unindent
function IndentLine(increment)
  if state.wpi == nil then return end
  local indent = state.waypoints[state.wpi].indent + increment
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
  if state.wpi == nil or state.wpi == #state.waypoints then return end
  state.wpi = u.clamp(
    state.wpi + 1,
    1,
    #state.waypoints
  )
  draw("move_to_waypoint")
end



function PrevWaypoint()
  if state.wpi == nil or state.wpi == 1 then return end
  state.wpi = u.clamp(
    state.wpi - 1,
    1,
    #state.waypoints
  )
  draw("move_to_waypoint")
end



function GoToWaypoint()
  if state.wpi == nil then return end

  Leave()
  --- @type Waypoint | nil 
  local waypoint = state.waypoints[state.wpi]
  if waypoint == nil then vim.api.nvim_err_writeln("waypoint should not be nil") return end
  local extmark = u.extmark_for_waypoint(waypoint)

  local waypoint_bufnr = vim.fn.bufnr(waypoint.filepath)
  vim.api.nvim_win_set_buf(0, waypoint_bufnr)
  vim.api.nvim_win_set_cursor(0, { extmark[1] + 1, 0 })
  vim.api.nvim_command("normal! zz")
end


function IncreaseContext(increment)
  state.context = u.clamp(state.context + increment, 0)
  draw("context")
end


function IncreaseBeforeContext(increment)
  state.before_context = u.clamp(state.before_context + increment, 0)
  draw("context")
end


function IncreaseAfterContext(increment)
  state.after_context = u.clamp(state.after_context + increment, 0)
  draw("context")
end


function ResetContext()
  state.context = 0
  state.before_context = 0
  state.after_context = 0
  draw()
end


function Scroll(increment)
  local width = vim.api.nvim_get_option("columns")
  local win_width = math.ceil(width * config.window_width)
  local col = state.scroll_col
  state.scroll_col = u.clamp(state.scroll_col + increment, 0, longest_line_len - win_width)
  u.p("SCROLL", col, state.scroll_col)
  draw("scroll")
end


function ResetScroll()
  state.scroll_col = 0
  draw("scroll")
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

function ResetIndent()
  for _,waypoint in pairs(state.waypoints) do
    waypoint.indent = 0
  end
  draw()
end

function SetWaypointForCursor()
  if ignore_next_cursormoved then
    ignore_next_cursormoved = false
    return
  end

  if not line_to_waypoint then return end
  local cursor_line_1i = vim.api.nvim_win_get_cursor(0)[1]
  if not cursor_line_1i then return end
  state.wpi = line_to_waypoint[cursor_line_1i]
  local view = vim.fn.winsaveview()
  u.p("SWFC left", view.leftcol, "scroll", state.scroll_col)
  state.scroll_col = view.leftcol
  draw("set_waypoint_for_cursor")
end

function Resize()
  local win_opts = get_win_opts()
  local bg_win_opts = get_bg_win_opts(win_opts)
  vim.api.nvim_win_set_config(winnr, win_opts)
  vim.api.nvim_win_set_config(bg_winnr, bg_win_opts)
end

function RemoveCurrentWaypoint()
  crud.remove_waypoint(state.wpi, state.waypoints[state.wpi].filepath)
  if #state.waypoints == 0 then
    state.wpi = nil
  end
  state.wpi = u.clamp(state.wpi, 1, #state.waypoints)
  draw()
end

function M.open()
  if state.wpi == nil and #state.waypoints > 0 then
    state.wpi = 1
  end
  local is_listed = false
  local is_scratch = false

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

  vim.api.nvim_create_autocmd("WinLeave", {
    group = constants.augroup,
    buffer = bufnr,
    callback = Close,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = constants.augroup,
    buffer = bufnr,
    callback = SetWaypointForCursor,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = constants.augroup,
    callback = Resize,
  })

  local win_opts = get_win_opts()
  local bg_win_opts = get_bg_win_opts(win_opts)

  -- Create the background
  bg_winnr = vim.api.nvim_open_win(bg_bufnr, false, bg_win_opts)

  -- Create the window
  winnr = vim.api.nvim_open_win(bufnr, true, win_opts)

  -- I added this because if you open waypoint from telescope, it has wrap disabled
  -- I'm sure there are a bunch of other edge cases like this lurking around
  vim.api.nvim_win_set_option(winnr, "wrap", false)

  -- u.p(vim.api.nvim_win_get_option(winnr, "winhl"))
  u.p("HL", vim.api.nvim_get_hl(winnr, { name = "Normal" }))

  state.scroll_col = 0
  draw("move_to_waypoint")

  local function keymap_opts()
    return {
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q',     ":lua Leave()<CR>",                   keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<esc>', ":lua Leave()<CR>",                   keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", ">",     ":lua IndentLine(4)<CR>",             keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<",     ":lua IndentLine(-4)<CR>",            keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "i",     ":lua ResetIndent()<CR>",             keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "l",     ":lua Scroll(6)<CR>",                 keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "h",     ":lua Scroll(-6)<CR>",                keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "0",     ":lua ResetScroll()<CR>",             keymap_opts())

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

  vim.api.nvim_buf_set_keymap(bufnr, "n", "ta",    ":lua ToggleAnnotation()<CR>",        keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tp",    ":lua TogglePath()<CR>",              keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tf",    ":lua ToggleFullPath()<CR>",          keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tl",    ":lua ToggleLineNum()<CR>",           keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tt",    ":lua ToggleFileText()<CR>",          keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "dd",    ":lua RemoveCurrentWaypoint()<CR>",   keymap_opts())
end

function Close()
  vim.api.nvim_win_close(bg_winnr, true)
  vim.api.nvim_win_close(winnr, true)
end

function Leave()
  vim.cmd("wincmd w")
  -- vim.api.nvim_set_current_win(prev_window_handle)
end

return M
