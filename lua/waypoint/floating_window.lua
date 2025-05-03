local M = {}

local config = require("waypoint.config")
local crud = require("waypoint.waypoint_crud")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local p = require("waypoint.print")
local highlight = require("waypoint.highlight")

local is_open = false
local bufnr
local bg_bufnr
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
  bg_win_opts.title = {{" Waypoints ", "FloatBorder"}}
  -- todo: make the background of this equal to window background
  -- between the A, B, and C indicators
  local sep = {" ─── ", 'FloatBorder' } -- give it the background of the rest of the floating window
  local a = {"A: " .. state.after_context, constants.hl_footer_after_context }
  local b = {"B: " .. state.before_context, constants.hl_footer_before_context }
  local c = {"C: " .. state.context, constants.hl_footer_context }
  local wpi
  if state.wpi == nil then
    wpi = {"No waypoints", constants.hl_footer_waypoint_nr}
  else
    wpi = {state.wpi .. '/' .. #state.waypoints, constants.hl_footer_waypoint_nr }
  end
  bg_win_opts.footer = {
    { "─ ", 'FloatBorder'},
    { "Press g? for help", constants.hl_selected },
    sep, a, sep, b, sep, c, sep, wpi,
    { " ", 'FloatBorder'},
  }
  bg_win_opts.title_pos = "center"
  return bg_win_opts
end


local function draw(action)
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

  --- @type table<table<string | table<waypoint.HighlightRange>>>
  --- first index is the line number, second is the column index. each column 
  --- highlight is either a string or a table of highlight ranges. if string, 
  --- highlight the whole column using the group whose name is the string. 
  --- Otherwise, apply each highlight in the table.
  local hlranges = {}

  for i, waypoint in ipairs(state.waypoints) do
    --- @type waypoint.WaypointFileText
    local waypoint_file_text = uw.get_waypoint_context(
      waypoint,
      state.before_context + state.context,
      state.after_context + state.context
    )
    local extmark_lines = waypoint_file_text.lines
    local extmark_line_0i = waypoint_file_text.waypoint_linenr
    local context_start_line_nr_0i = waypoint_file_text.context_start_linenr
    local extmark_hlranges = waypoint_file_text.highlight_ranges
    assert(extmark_lines)

    if i == state.wpi then
      highlight_start = #rows
      waypoint_topline = #rows + 1
      waypoint_bottomline = #rows + #extmark_lines
      cursor_line = #rows + extmark_line_0i
    end

    for j, line_text in ipairs(extmark_lines) do
      local line_hlranges = {}
      --- @type table<waypoint.HighlightRange>
      local line_extmark_hlranges = extmark_hlranges[j]
      table.insert(indents, waypoint.indent)
      table.insert(line_to_waypoint, i)
      local row = {}

      -- waypoint number and mark char 
      if j == extmark_line_0i + 1 then
        -- if this is line the waypoint is on
        table.insert(row, tostring(i))
        -- table.insert(row, config.mark_char)
        table.insert(line_hlranges, {})
        -- table.insert(line_hlranges, constants.hl_sign)
      else
        -- if this is a line in the context around the waypoint
        table.insert(row, "")
        -- table.insert(row, "")
        table.insert(line_hlranges, {})
        -- table.insert(line_hlranges, {})
      end

      -- file path
      if state.show_path then
        if state.show_full_path then
          table.insert(row, waypoint.filepath)
          table.insert(line_hlranges, constants.hl_directory)
        else
          local filename = vim.fn.fnamemodify(waypoint.filepath, ":t")
          table.insert(row, filename)
          table.insert(line_hlranges, constants.hl_directory)
        end
      end

      -- line number
      if state.show_line_num then
        table.insert(row, tostring(context_start_line_nr_0i + j))
        table.insert(line_hlranges, constants.hl_linenr)
      end

      -- file text
      if state.show_file_text then
        table.insert(row, line_text)
        table.insert(line_hlranges, line_extmark_hlranges)
      end

      for _,v in pairs(row) do
        if v == nil then
          u.log(row)
        end
      end

      table.insert(rows, row)
      table.insert(hlranges, line_hlranges)
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
      table.insert(hlranges, {})
    end
  end

  assert(#rows == #indents, "#rows == " .. #rows ..", #indents == " .. #indents .. ", but they should be the same" )
  assert(#rows == #line_to_waypoint, "#rows == " .. #rows ..", #line_to_waypoint == " .. #line_to_waypoint .. ", but they should be the same" )
  assert(#rows == #hlranges, "#rows == " .. #rows ..", #hlranges == " .. #hlranges .. ", but they should be the same" )

  local table_cell_types = {"number"}
  if state.show_path then
    table.insert(table_cell_types, "string")
  end
  if state.show_line_num then
    table.insert(table_cell_types, "number")
  end
  if state.show_file_text then
    table.insert(table_cell_types, "string")
  end

  local win_width = get_floating_window_width()
  local aligned = uw.align_waypoint_table(rows, table_cell_types, hlranges, win_width)

  longest_line_len = 0
  for i, line in pairs(aligned) do
    aligned[i] = string.rep(" ", indents[i]) .. line
    longest_line_len = math.max(longest_line_len, vim.fn.strchars(aligned[i]))
  end

  -- Set text in the buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, aligned)

  -- highlight the text in the buffer
  for lnum,line_hlranges in pairs(hlranges) do
    for _,col_highlights in pairs(line_hlranges) do
      if type(col_highlights) == "string" then
        assert(false, "This should not happen, align_tables should change all column-wide highlights to a HighlightRange")
      else
        for _,hlrange in pairs(col_highlights) do
          vim.api.nvim_buf_set_extmark(bufnr, constants.ns, lnum - 1, hlrange.col_start + indents[lnum], {
            end_col = hlrange.col_end + indents[lnum], -- 0-based column number
            hl_group = hlrange.hl_group,                   -- Highlight group to apply
          })

          -- vim.api.nvim_buf_add_highlight(
          --   bufnr,
          --   hlrange.nsid,
          --   hlrange.hl_group,
          --   lnum - 1,
          --   hlrange.col_start,
          --   hlrange.col_end
          -- )
        end
      end
    end
  end
  if state.wpi and highlight_start and highlight_end and cursor_line then
    if action == "move_to_waypoint" or action == "context" then
      vim.fn.setcursorcharpos(cursor_line + 1, state.view.col + 1)
    end

    if action == "scroll" or action == "context" then
      local lnum
      if state.view.lnum == nil then
        lnum = vim.fn.getcursorcharpos()[2]
      else
        lnum = state.view.lnum
      end
      vim.fn.setcursorcharpos(lnum, state.view.col + 1)
      local view = vim.fn.winsaveview()
      view.leftcol = state.view.leftcol
      vim.fn.winrestview({leftcol = state.view.leftcol})
    else
      local view = vim.fn.winsaveview()
      local topline = view.topline

      local win_height = get_floating_window_height()
      if waypoint_topline < topline then
        view.topline = waypoint_topline
      elseif topline + win_height < waypoint_bottomline then
        view.topline = waypoint_bottomline - win_height
      end
      vim.fn.winrestview(view)
    end


    for i=highlight_start,highlight_end-1 do
      vim.api.nvim_buf_add_highlight(bufnr, 0, constants.hl_selected, i, 0, -1)
    end
  end

  -- update window config, used to update the footer a/b/c indicators and the size of the window
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
  state.waypoints[state.wpi].indent = u.clamp(
    indent, 0, constants.max_indent * config.indent_width
  )
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
  -- center on selected waypoint
  state.view.lnum = nil
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
  local extmark = uw.extmark_for_waypoint(waypoint)

  local waypoint_bufnr = vim.fn.bufnr(waypoint.filepath)
  vim.api.nvim_win_set_buf(0, waypoint_bufnr)
  vim.api.nvim_win_set_cursor(0, { extmark[1] + 1, 0 })
  vim.api.nvim_command("normal! zz")
end

local function clamp_view()
  local width = vim.api.nvim_get_option("columns")
  local win_width = math.ceil(width * config.window_width)
  local leftcol_max = u.clamp(longest_line_len - win_width, 0)
  state.view.leftcol = u.clamp(state.view.leftcol, 0, leftcol_max)
  state.view.col = u.clamp(state.view.col, state.view.leftcol, state.view.leftcol + win_width - 1)
end


function IncreaseContext(increment)
  state.context = u.clamp(state.context + increment, 0)
  state.view.lnum = nil
  clamp_view()
  draw("context")
end


function IncreaseBeforeContext(increment)
  state.before_context = u.clamp(state.before_context + increment, 0)
  state.view.lnum = nil

  clamp_view()
  draw("context")
end


function IncreaseAfterContext(increment)
  state.after_context = u.clamp(state.after_context + increment, 0)
  state.view.lnum = nil

  clamp_view()
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
  local leftcol_max = u.clamp(longest_line_len - win_width, 0)
  state.view.leftcol = u.clamp(state.view.leftcol + increment, 0, leftcol_max)
  state.view.col = u.clamp(state.view.col, state.view.leftcol, state.view.leftcol + win_width - 1)
  draw("scroll")
end


function ResetScroll()
  state.view.col = 0
  state.view.leftcol = 0
  draw("scroll")
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

function ResetCurrentIndent()
  if state.wpi then
    state.waypoints[state.wpi].indent = 0
  end
  draw()
end

function ResetAllIndent()
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
  -- use getcursorcharpos to avoid issues with unicode
  local cursor_pos = vim.fn.getcursorcharpos()
  print(cursor_pos[2])
  state.view.lnum = cursor_pos[2]
  state.view.col = cursor_pos[3] - 1

  local view = vim.fn.winsaveview()
  state.view.leftcol = view.leftcol
  state.wpi = line_to_waypoint[state.view.lnum]
  draw("set_waypoint_for_cursor")
end

function Resize()
  local win_opts = get_win_opts()
  local bg_win_opts = get_bg_win_opts(win_opts)
  vim.api.nvim_win_set_config(winnr, win_opts)
  vim.api.nvim_win_set_config(bg_winnr, bg_win_opts)
end

function RemoveCurrentWaypoint()
  if #state.waypoints == 0 then return end
  crud.remove_waypoint(state.wpi, state.waypoints[state.wpi].filepath)
  if #state.waypoints == 0 then
    state.wpi = nil
  else
    state.wpi = u.clamp(state.wpi, 1, #state.waypoints)
  end
  draw()
end

function SetQFList()
  local qflist = {}
  for _,waypoint in pairs(state.waypoints) do
    local wp_bufnr = vim.fn.bufnr(waypoint.filepath)
    local extmark = vim.api.nvim_buf_get_extmark_by_id(wp_bufnr, constants.ns, waypoint.extmark_id, {})
    local lnum = extmark[1]
    local line = vim.api.nvim_buf_get_lines(wp_bufnr, lnum, lnum + 1, false)[1]
    table.insert(qflist, {
      filename = waypoint.filepath,
      lnum = lnum,
      col = 0,
      text = line,
    })
  end
  vim.fn.setqflist(qflist, 'r')
  vim.cmd('copen')
end

function ShowHelp()
  -- -- Define the items to display in the popup
  -- local items = { "Option 1", "Option 2", "Option 3" }
  --
  -- -- Define a function to show the popup
  -- local function show_g_popup()
  --   vim.ui.select(items, {
  --     prompt = "Select an option:",
  --     format_item = function(item)
  --       return "> " .. item
  --     end,
  --   }, function(choice)
  --       if choice then
  --         print("You selected: " .. choice)
  --       end
  --     end)
  -- end
  -- show_g_popup()

  -- Create a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set some content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "Press <Esc> to close",
    "",
    "This is a custom popup!",
    "You can put anything here.",
  })

  -- Get current UI dimensions
  local width = 40
  local height = 5
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create a floating window
  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
  }


  -- to avoid triggering the autocmds that close the floating window when you leave the buffer or window
  vim.opt.eventignore:append({ "BufLeave", "WinLeave" })  -- Disable specific events
  local win = vim.api.nvim_open_win(buf, true, opts)
  -- turn them back on after we're done
  vim.opt.eventignore:remove({ "BufLeave", "WinLeave" })  -- Re-enable

  vim.api.nvim_create_autocmd("WinLeave", {
    group = constants.augroup,
    buffer = buf,
    callback = function()
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, {})
      vim.api.nvim_set_current_win(winnr)
    end,
  })

  -- Close on Escape
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
end

M.ShowHelp = ShowHelp


function M.open()
  if is_open then
    return
  else
    is_open = true
  end
  if state.wpi == nil and #state.waypoints > 0 then
    state.wpi = 1
  end
  local is_listed = false
  local is_scratch = false

  bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)
  bg_bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)

  vim.bo[bufnr].buftype = "nofile" -- Prevents the buffer from being treated as a normal file
  vim.bo[bufnr].bufhidden = "wipe" -- Ensures the buffer is removed when closed
  vim.bo[bufnr].swapfile = false   -- Prevents swap file creation

  -- this extension does not support wrap, all long lines will overflow off the
  -- edge of the screen
  vim.api.nvim_buf_set_option(bufnr, 'wrap', false)

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

  -- account for some color schemes having ridiculous colors for 
  -- the default floating window background.
  if u.hl_background_distance("Normal", "NormalFloat") > 300 then
    vim.api.nvim_win_set_option(winnr, 'winhl', 'NormalFloat:Normal')
    vim.api.nvim_win_set_option(bg_winnr, 'winhl', 'NormalFloat:Normal')
  end

  -- I added this because if you open waypoint from telescope, it has wrap disabled
  -- I'm sure there are a bunch of other edge cases like this lurking around
  vim.api.nvim_win_set_option(winnr, "wrap", false)

  state.view.leftcol = 0
  draw("move_to_waypoint")

  local function keymap_opts()
    return {
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  -- highlight
  highlight.highlight_custom_groups()

  -- keymaps
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q',     ":lua Leave()<CR>",                                        keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<esc>', ":lua Leave()<CR>",                                        keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", ">",     ":lua IndentLine(" .. config.indent_width .. ")<CR>",      keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<",     ":lua IndentLine(" .. -1 * config.indent_width .. ")<CR>", keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "ri",    ":lua ResetCurrentIndent()<CR>",                                  keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "rI",    ":lua ResetAllIndent()<CR>",                                  keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "L",     ":lua Scroll(6)<CR>",                                      keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "H",     ":lua Scroll(-6)<CR>",                                     keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "0",     ":lua ResetScroll()<CR>",                                  keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "rs",    ":lua ResetScroll()<CR>",                                  keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "j",     ":lua NextWaypoint()<CR>",                                 keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "k",     ":lua PrevWaypoint()<CR>",                                 keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "K",     ":lua MoveWaypointUp()<CR>",                               keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "J",     ":lua MoveWaypointDown()<CR>",                             keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>",  ":lua GoToWaypoint()<CR>",                                 keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "c",     ":lua IncreaseContext(1)<CR>",                             keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "C",     ":lua IncreaseContext(-1)<CR>",                            keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "b",     ":lua IncreaseBeforeContext(1)<CR>",                       keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "B",     ":lua IncreaseBeforeContext(-1)<CR>",                      keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "a",     ":lua IncreaseAfterContext(1)<CR>",                        keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "A",     ":lua IncreaseAfterContext(-1)<CR>",                       keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "R",     ":lua ResetContext()<CR>",                                 keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "tp",    ":lua TogglePath()<CR>",                                   keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tf",    ":lua ToggleFullPath()<CR>",                               keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tl",    ":lua ToggleLineNum()<CR>",                                keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tn",    ":lua ToggleLineNum()<CR>",                                keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tt",    ":lua ToggleFileText()<CR>",                               keymap_opts())

  vim.api.nvim_buf_set_keymap(bufnr, "n", "dd",    ":lua RemoveCurrentWaypoint()<CR>",                        keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "Q",     ":lua SetQFList()<CR>",                                    keymap_opts())
  vim.api.nvim_buf_set_keymap(bufnr, "n", "g?",    ":lua ShowHelp()<CR>",                                     keymap_opts())
end

function Close()
  vim.api.nvim_win_close(bg_winnr, true)
  vim.api.nvim_win_close(winnr, true)
  vim.api.nvim_buf_delete(bg_bufnr, {})
  -- vim.api.nvim_buf_delete(bufnr, {})
  is_open = false
  bufnr = nil
  bg_bufnr = nil
  winnr = nil
  bg_winnr = nil
end

function Leave()
  vim.cmd("wincmd w")
  -- vim.api.nvim_set_current_win(prev_window_handle)
end

return M
