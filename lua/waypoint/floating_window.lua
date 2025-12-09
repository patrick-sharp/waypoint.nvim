local M = {}

local config = require("waypoint.config")
local crud = require("waypoint.waypoint_crud")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local p = require("waypoint.print")
local highlight = require("waypoint.highlight")

-- these are some pieces of window state that don't belong in the main state
-- table because they shouldn't be persisted to a file
local is_open = false
local wp_bufnr
local bg_bufnr
local help_bufnr
local winnr
local bg_winnr
-- if the user does something to move the cursor to another line, we want to set
-- the new selected waypoint to whatever waypoint the cursor is currently on
local line_to_waypoint
local longest_line_len

local function keymap_opts(bufnr)
  return {
    noremap = true,
    silent = true,
    nowait = true,
    buffer = bufnr,
  }
end

local sorted_mode_err_msg_table = {"Cannot move waypoints while sort is enabled. Press "}
local toggle_sort = config.keybindings.waypoint_window_keybindings.toggle_sort
if type(toggle_sort) == "string" then
  table.insert(sorted_mode_err_msg_table, toggle_sort)
else
  for i, kb in ipairs(toggle_sort) do
    if i ~= 1 then
      table.insert(sorted_mode_err_msg_table, " or ")
    end
    table.insert(sorted_mode_err_msg_table, kb)
  end
end
table.insert(sorted_mode_err_msg_table, " to toggle sort")

local sorted_mode_err_msg = table.concat(sorted_mode_err_msg_table)

-- I use this to avoid drawing twice when the cursor moves.
-- I have no idea how nvim orders events and event handlers so hopefully this 
-- isn't a catastrophe waiting to happen
local ignore_next_cursormoved

local function set_modifiable(bufnr, is_modifiable)
  if bufnr == nil then error("Should not be called before initializing window") end
  vim.bo[bufnr].modifiable = is_modifiable
  vim.bo[bufnr].readonly = not is_modifiable
end


local function get_total_width()
  return vim.api.nvim_get_option_value("columns", {})
end

local function get_total_height()
  local height = vim.api.nvim_get_option_value("lines", {})
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

---@param option boolean
---@return string
local function get_toggle_hl(option)
  if option then
    return constants.hl_toggle_on
  end
  return constants.hl_toggle_off
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

  -- toggles
  local annotation = {"A", get_toggle_hl(state.show_annotation) }
  local path =       {"N", get_toggle_hl(state.show_line_num) }
  local num =        {"P", get_toggle_hl(state.show_path) }
  local full_path =  {"F", get_toggle_hl(state.show_full_path) }
  local text =       {"T", get_toggle_hl(state.show_file_text) }
  local context =    {"C", get_toggle_hl(state.show_context) }
  local sort =       {"S", get_toggle_hl(state.sort_by_file_and_line) }

  local wpi
  if state.wpi == nil then
    wpi = {"No waypoints", constants.hl_footer_waypoint_nr}
  else
    wpi = {state.wpi .. '/' .. #state.waypoints, constants.hl_footer_waypoint_nr }
  end
  bg_win_opts.footer = {
    { "─ ", 'FloatBorder'},
    { "Press g? for help", constants.hl_selected },
    sep, a, sep, b, sep, c, sep, wpi, sep,
    annotation, num, path, full_path, text, context, sort,
    { " ", 'FloatBorder'},
  }
  bg_win_opts.title_pos = "center"
  return bg_win_opts
end

local function repair_state()

end

local function draw_waypoint_window(action)
  set_modifiable(wp_bufnr, true)

  if state.load_error then
    vim.api.nvim_buf_set_lines(wp_bufnr, 0, -1, true, {
      state.load_error,
      "Press <TBD> to delete the file and clear all waypoint state"
    })
    set_modifiable(wp_bufnr, false)
    return
  end

  -- this is the only thing we do in this function that mutates state.
  -- In general, I want draw_waypoint_window to be a pure function of state that draws the contents of the window.
  -- However, sometimes data in state can get stale.
  -- Examples: 
  --   a file gets renamed, so the waypoint filepath is no longer correct.
  --   a file gets closed, so the waypoint buffer number and extmark id are no longer correct.
  repair_state()

  vim.api.nvim_buf_clear_namespace(wp_bufnr, constants.ns, 0, -1)
  local rows = {}
  local indents = {}
  ---@type integer[]
  line_to_waypoint = {}

  local cursor_line
  local waypoint_topline
  local waypoint_bottomline

  local highlight_start
  local highlight_end

  --- @type (string | waypoint.HighlightRange[])[][]
  --- first index is the line number, second is the column index. each column 
  --- highlight is either a string or a table of highlight ranges. if string, 
  --- highlight the whole column using the group whose name is the string. 
  --- Otherwise, apply each highlight in the table.
  local hlranges = {}

  local num_lines_before
  local num_lines_after
  if state.show_context then
    num_lines_before = state.before_context + state.context
    num_lines_after = state.after_context + state.context
  else
    num_lines_before = 0
    num_lines_after = 0
  end


  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end


  for i, waypoint in ipairs(waypoints) do
    --- @type waypoint.WaypointFileText
    local waypoint_file_text = uw.get_waypoint_context(
      waypoint,
      num_lines_before,
      num_lines_after
    )
    local extmark_lines = waypoint_file_text.lines
    local extmark_line = waypoint_file_text.waypoint_linenr -- zero-indexed
    local context_start_linenr = waypoint_file_text.context_start_linenr -- zero-indexed
    local extmark_hlranges = waypoint_file_text.highlight_ranges
    local file_start_idx = waypoint_file_text.file_start_idx
    local file_end_idx = waypoint_file_text.file_end_idx
    assert(extmark_lines)

    if i == state.wpi then
      highlight_start = #rows
      waypoint_topline = #rows + 1
      waypoint_bottomline = #rows + #extmark_lines
      cursor_line = #rows + extmark_line
    end

    for j, line_text in ipairs(extmark_lines) do
      local line_hlranges = {}
      --- @type waypoint.HighlightRange[]
      local line_extmark_hlranges = extmark_hlranges[j]
      table.insert(indents, waypoint.indent * config.indent_width)
      table.insert(line_to_waypoint, i)
      local row = {}

      -- waypoint number
      if j == extmark_line + 1 then
        -- if this is line the waypoint is on
        if config.enable_relative_waypoint_numbers then
          if i == state.wpi then
            table.insert(row, tostring(state.wpi))
          else
            table.insert(row, tostring((math.abs(i - state.wpi))))
          end
        else
          table.insert(row, tostring(i))
        end
        table.insert(line_hlranges, {})
      else
        -- if this is a line in the context around the waypoint
        table.insert(row, "")
        table.insert(line_hlranges, {})
      end

      -- file path
      if state.show_path then
        if j == extmark_line + 1 then
          -- if this is line the waypoint is on
          if state.show_full_path then
            -- if we're showing the full path
            table.insert(row, waypoint.filepath)
            table.insert(line_hlranges, constants.hl_directory)
          else
            -- if we're just showing the filename
            local filename = vim.fn.fnamemodify(waypoint.filepath, ":t")
            table.insert(row, filename)
            table.insert(line_hlranges, constants.hl_directory)
          end
        else
          -- if this is a line in the context around the waypoint
          table.insert(row, "")
          table.insert(line_hlranges, {})
        end
      end

      -- line number
      if state.show_line_num then
        if j >= file_start_idx and j < file_end_idx then
          table.insert(row, tostring(context_start_linenr + j - file_start_idx + 1))
        else
          table.insert(row, "")
        end
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
    if state.show_context and has_context and i < #waypoints then
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
  local aligned = uw.align_waypoint_table(
    rows, table_cell_types, hlranges,
    {
      column_separator = constants.table_separator,
      win_width = win_width,
      indents = indents,
    })

  longest_line_len = 0
  for i, line in pairs(aligned) do
    aligned[i] = string.rep(" ", indents[i]) .. line
    longest_line_len = math.max(longest_line_len, vim.fn.strchars(aligned[i]))
  end

  -- Set text in the buffer
  vim.api.nvim_buf_set_lines(wp_bufnr, 0, -1, true, aligned)

  -- highlight the text in the buffer
  for lnum,line_hlranges in pairs(hlranges) do
    for _,col_highlights in pairs(line_hlranges) do
      if type(col_highlights) == "string" then
        assert(false, "This should not happen, align_waypoint_table should change all column-wide highlights to a HighlightRange")
      else
        for i,hlrange in pairs(col_highlights) do
          vim.api.nvim_buf_set_extmark(wp_bufnr, constants.ns, lnum - 1, hlrange.col_start + indents[lnum], {
            end_col = hlrange.col_end + indents[lnum], -- 0-based exclusive column upper bound is the same as 1 based inclusive
            hl_group = hlrange.hl_group,               -- Highlight group to apply
            -- need to set priority here because extmarks don't override each
            -- other. I had a bug where the color of a highlighted range would
            -- change every n keypresses, where n was something like 10. I have
            -- no idea why, but the cause seems to be that in treesitter, some
            -- highlights cover the exact same area but with a different color.
            -- Treesitter seems to always return the highest priority highlight
            -- range last, but in neovim it appears that if you draw an extmark,
            -- then draw an extmark with a different color in the exact same
            -- range as the other one, it won't necessarily override. to fix 
            -- this, I set the priority of the extmark to be its position in the
            -- list. This makes sure that highlights treesitter puts later get
            -- higher priority.
            priority=i,
          })

          -- commenting this out to use extmarks instead of highlight ranges
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
    -- for certain actions, we need to move the cursor to where the state view says it is
    local should_move_cursor = (
      action == "move_to_waypoint"
      or action == "context"
      or action == "swap"
    )

    if should_move_cursor then
      vim.fn.setcursorcharpos(cursor_line + 1, state.view.col + 1)
    end

    if action == "scroll" or action == "context" then
      --- @type integer
      local lnum
      if state.view.lnum == nil then
        lnum = vim.fn.getcursorcharpos()[2]
      else
        lnum = state.view.lnum
      end
      assert(lnum)
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
      vim.hl.range(wp_bufnr, constants.ns, constants.hl_selected, {i, 0}, {i, -1})
    end
  end

  -- update window config, used to update the footer a/b/c indicators and the size of the window
  local win_opts = get_win_opts()
  local bg_win_opts = get_bg_win_opts(win_opts)
  vim.api.nvim_win_set_config(winnr, win_opts)
  vim.api.nvim_win_set_config(bg_winnr, bg_win_opts)

  set_modifiable(wp_bufnr, false)
  if action == "center" or action == "context" then
    vim.api.nvim_command("normal! zz")
  end
  if action ~= "set_waypoint_for_cursor" then
    ignore_next_cursormoved = true
  end
end

-- binds the keybinding (or keybindings) to the given action 
--- @param keybinding string | string[]
--- @param fn string | function the vim mapping string that this keybind should perform
local function bind_key(bufnr, keybinding, fn)
  if type(keybinding) == "string" then
    vim.keymap.set('n', keybinding, fn, keymap_opts(bufnr))
  elseif type(keybinding) == "table" then
    for i, v in ipairs(keybinding) do
      if type(v) ~= "string" then
        error("Type of element " .. i .. " of keybinding should be string, but was " .. type(v) .. ".")
      end
      vim.keymap.set('n', v, fn, keymap_opts(bufnr))
    end
  else
    error("Type of param keybinding should be string or table, but was " .. type(keybinding) .. ".")
  end
end

-- shared between the help buffer and the waypoint buffer
local function set_shared_keybinds(bufnr)
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.exit_waypoint_window,    ":lua Leave()<CR>")

  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.increase_context,        M.increase_context)
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.decrease_context,        M.decrease_context)
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.increase_before_context, M.increase_before_context)
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.decrease_before_context, M.decrease_before_context)
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.increase_after_context,  ":<C-u>lua IncreaseAfterContext(1)<CR>")
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.decrease_after_context,  ":<C-u>lua IncreaseAfterContext(-1)<CR>")
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.reset_context,           ":<C-u>lua ResetContext()<CR>")

  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.toggle_annotation,       ":lua ToggleAnnotation()<CR>")
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.toggle_path,             ":lua TogglePath()<CR>")
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.toggle_full_path,        M.toggle_full_path)
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.toggle_line_num,         ":lua ToggleLineNum()<CR>")
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.toggle_file_text,        ":lua ToggleFileText()<CR>")
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.toggle_context,          ":lua ToggleContext()<CR>")
  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.toggle_sort,             M.toggle_sort)

  bind_key(bufnr, config.keybindings.waypoint_window_keybindings.set_quickfix_list,       ":<C-u>lua SetQFList()<CR>")
end

local function set_help_keybinds()
  set_shared_keybinds(help_bufnr)
  bind_key(help_bufnr, config.keybindings.help_keybindings.exit_help, ":lua ToggleHelp()<CR>")
end

local function set_waypoint_keybinds()
  set_shared_keybinds(wp_bufnr)

  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.show_help,            ":<C-u>lua ToggleHelp()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.exit_waypoint_window, ":lua Leave()<CR>")

  if state.load_error then
    vim.keymap.set('n', '<CR>', M.clear_state, keymap_opts(wp_bufnr))
    return
  end

  -- the <C-u> before the colon some keymaps allows them to be used with counts.
  -- normally, typing a count and then colon will put you in command mode with 
  -- .,.+count in front, which applies the command to the next <count> lines. 
  -- for example, type 6 and then : will put you into command mode with :.,.+5
  -- preset. If you run :.,.+5yank you will copy the current line and the 5 
  -- lines after it.
  -- The <C-u> is the bind to delete everything from the current cursor position
  -- to the colon in command mode.
  -- the actual function you're binding has to access vim.v.count or 
  -- vim.v.count1 to access the count.

  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.indent,                  ":<C-u>lua IndentLine(1)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.unindent,                ":<C-u>lua IndentLine(-1)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.reset_waypoint_indent,   ":lua ResetCurrentIndent()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.reset_all_indent,        ":lua ResetAllIndent()<CR>")

  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.scroll_left,             ":<C-u>lua Scroll(1)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.scroll_right,            ":<C-u>lua Scroll(-1)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.reset_horizontal_scroll, ":lua ResetScroll()<CR>")

  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.prev_waypoint,           ":lua PrevWaypoint()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.next_waypoint,           ":lua NextWaypoint()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.first_waypoint,          ":lua MoveToFirstWaypoint()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.last_waypoint,           ":lua MoveToLastWaypoint()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.prev_neighbor_waypoint,  ":<C-u>lua MoveToPrevNeighborWaypoint(true)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.next_neighbor_waypoint,  ":<C-u>lua MoveToNextNeighborWaypoint(true)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.prev_top_level_waypoint, ":<C-u>lua MoveToPrevTopLevelWaypoint(true)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.next_top_level_waypoint, ":<C-u>lua MoveToNextTopLevelWaypoint(true)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.outer_waypoint,          ":<C-u>lua MoveToOuterWaypoint(true)<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.inner_waypoint,          ":<C-u>lua MoveToInnerWaypoint(true)<CR>")

  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.move_waypoint_up,        ":<C-u>lua MoveWaypointUp()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.move_waypoint_down,      ":<C-u>lua MoveWaypointDown()<CR>")
  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.current_waypoint,        ":<C-u>lua GoToCurrentWaypoint()<CR>")

  bind_key(wp_bufnr, config.keybindings.waypoint_window_keybindings.delete_waypoint,        ":<C-u>lua RemoveCurrentWaypoint()<CR>")

  -- vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "sg",    ":lua MoveWaypointToTop()<CR>",                   keymap_opts)
  -- vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "sG",    ":lua MoveWaypointToBottom()<CR>",                keymap_opts)
end

local global_keybindings_description = {
  {"toggle_waypoint"         ,  "Toggle a waypoint on the cursor's current line"}       ,
  {"open_waypoint_window"    ,  "Show the waypoint window"}                             ,
  {"current_waypoint"        ,  "Jump to current waypoint"}                             ,
  {"prev_waypoint"           ,  "Jump to previous waypoint"}                            ,
  {"next_waypoint"           ,  "Jump to next waypoint"}                                ,
  {"first_waypoint"          ,  "Jump to first waypoint"}                               ,
  {"last_waypoint"           ,  "Jump to last waypoint"}                                ,
  {"prev_neighbor_waypoint"  ,  "Jump to the previous waypoint at the same indentation"},
  {"next_neighbor_waypoint"  ,  "Jump to the next waypoint at the same indentation"}    ,
  {"prev_top_level_waypoint" ,  "Jump to the previous unindented waypoint"}             ,
  {"next_top_level_waypoint" ,  "Jump to the next unindented waypoint"}                 ,
  {"outer_waypoint"          ,  "Jump to the previous waypoint indented one level less"},
  {"inner_waypoint"          ,  "Jump to the next waypoint indented one level more"}    ,
}

local waypoint_window_keybindings_description = {
  {"current_waypoint"        , "Jump to the current waypoint's location"}                   ,
  {"delete_waypoint"         , "Delete the current waypoint from the waypoint list"}        ,
  {"move_waypoint_down"      , "Move the current waypoint before the previous waypoint"}    ,
  {"move_waypoint_up"        , "Move the current waypoint after the next waypoint"}         ,
  {"exit_waypoint_window"    , "Exit the waypoint window"}                                  ,
  {"increase_context"        , "Increase the number of lines shown around each waypoint"}   ,
  {"decrease_context"        , "Decrease the number of lines shown around each waypoint"}   ,
  {"increase_before_context" , "Increase the number of lines shown before each waypoint"}   ,
  {"decrease_before_context" , "Decrease the number of lines shown before each waypoint"}   ,
  {"increase_after_context"  , "Increase the number of lines shown after each waypoint"}    ,
  {"decrease_after_context"  , "Decrease the number of lines shown after each waypoint"}    ,
  {"reset_context"           , "Show no lines around each waypoint"}                        ,
  {"toggle_annotation"       , "I'm probably gonna remove this anyway"}                     ,
  {"toggle_path"             , "Toggle whether the file path appears"}                      ,
  {"toggle_full_path"        , "Toggle whether the full file path appears"}                 ,
  {"toggle_line_num"         , "Toggle whether the line number appears"}                    ,
  {"toggle_file_text"        , "Toggle whether the file text appears"}                      ,
  {"toggle_context"          , "Toggle whether any lines are shown around each waypoint"}   ,
  {"toggle_sort"             , "Toggle whether waypoints are sorted by file and line"}      ,
  {"show_help"               , "Show this help window"}                                     ,
  {"set_quickfix_list"       , "Set the quickfix list to locations of all waypoints"},
  {"indent"                  , "Increase the indentation of the current waypoint"}          ,
  {"unindent"                , "Decrease the indentation of the current waypoint"}          ,
  {"reset_waypoint_indent"   , "Set the current waypoint's indentation to zero"}            ,
  {"reset_all_indent"        , "Set the indentation of all waypoints to zero"}              ,
  {"scroll_right"            , "Scroll the waypoint window right"}                          ,
  {"scroll_left"             , "Scroll the waypoint window left"}                           ,
  {"reset_horizontal_scroll" , "Scroll the waypoint window all the way left"}               ,
  {"next_waypoint"           , "Move to the next waypoint in the waypoint window"}          ,
  {"prev_waypoint"           , "Move to the previous waypoint in the waypoint window"}      ,
  {"first_waypoint"          , "Move to the first waypoint in the waypoint window"}         ,
  {"last_waypoint"           , "Move to the last waypoint in the waypoint window"}          ,
  {"outer_waypoint"          , "Move to the previous waypoint indented one level less"}     ,
  {"inner_waypoint"          , "Move to the next waypoint indented one level more"}         ,
  {"prev_neighbor_waypoint"  , "Move to the previous waypoint at the same indentation"}     ,
  {"next_neighbor_waypoint"  , "Move to the next waypoint at the same indentation"}         ,
  {"prev_top_level_waypoint" , "Move to the previous unindented waypoint"}                  ,
  {"next_top_level_waypoint" , "Move to the next unindented waypoint"}                      ,
}

local help_keybindings_description = {
  {"exit_help", "Exit help and return to the waypoint window"},
}

local function insert_lines_for_keybindings(lines, highlights, keybindings_group, keybindings_description, keybindings_group_title, keybindings_group_name)
  table.insert(lines, "")
  table.insert(lines, "")
  table.insert(lines, keybindings_group_title .. " keybindings")
  table.insert(lines, "")
  table.insert(highlights, {})
  table.insert(highlights, {})
  table.insert(highlights, {})
  table.insert(highlights, {})

  local keybindings = {}
  local keybindings_highlights = {}

  for _, action_and_description in pairs(keybindings_description) do
    local action = action_and_description[1]
    local description = action_and_description[2]
    assert(keybindings_group[action], "No " .. keybindings_group_name.. " keybinding found for " .. action)
    local kb
    local kb_hl
    if type(keybindings_group[action]) == 'string' then
      kb = { description, keybindings_group[action], }
      kb_hl = {
        {},
        {{
          nsid = constants.ns,
          hl_group = constants.hl_keybinding,
          col_start = 1,
          col_end = #keybindings_group[action],
        }},
      }
    elseif type(keybindings_group[action]) == 'table' then
      local kb_col = {}
      local kb_hl_col = {}
      local separator = " or "
      local offset = 1
      for i, kb_ in pairs(keybindings_group[action]) do
        table.insert(kb_col, kb_)
        table.insert(kb_hl_col, {
          nsid = constants.ns,
          hl_group = constants.hl_keybinding,
          col_start = offset,
          col_end = offset + #kb_ - 1,
        })
        offset = offset + #kb_ + #separator
        if i < #keybindings_group[action] then
          table.insert(kb_col, separator)
        end
      end
      kb = {description, table.concat(kb_col)}
      kb_hl = {{}, kb_hl_col}
    else
      error("Type of " .. keybindings_group_name.. " keybinding for" .. action .. " should be string or table")
    end
    table.insert(keybindings, kb)
    table.insert(keybindings_highlights, kb_hl)
  end
  local aligned_keybindings = uw.align_waypoint_table(
    keybindings,
    {"string", "string"},
    keybindings_highlights,
    {
      column_separator = "",
      width_override = {55},
    }
  )
  for i=1,#keybindings do
    table.insert(lines, aligned_keybindings[i])
    local row_highlights = {}
    for j=1,#keybindings_highlights[i] do
      for k=1,#keybindings_highlights[i][j] do
        table.insert(row_highlights, keybindings_highlights[i][j][k])
      end
    end
    table.insert(highlights, row_highlights)
  end
end

local function draw_help()
  set_modifiable(help_bufnr, true)
  local lines = {}
  local highlights = {}

  -- info about state
  local prop_names = {
    {"show_annotation", "Show annotation:"},
    {"show_path", "Show file path:"},
    {"show_full_path", "Show full file path:"},
    {"show_file_text", "Show file text:"},
    {"show_context", "Show context:"},
    {"sort_by_file_and_line", "Sort by file and line number:"},
  }

  ---@type string[][]
  local toggles = {}
  ---@type waypoint.HighlightRange[][][]
  local toggle_highlights = {}
  for _,key_name in pairs(prop_names) do
    local key = key_name[1]
    local name = key_name[2]
    local on_off
    local hl_group
    if state[key] then
      on_off = "ON"
      hl_group = constants.hl_toggle_on
    else
      on_off = "OFF"
      hl_group = constants.hl_toggle_off
    end
    table.insert(toggles, { name, on_off })
    table.insert(toggle_highlights,
      {{}, {{
        nsid = constants.ns,
        hl_group = hl_group,
        col_start = 1,
        col_end = #on_off,
      }}}
    )
  end
  local aligned_toggles = uw.align_waypoint_table(toggles, {"string", "string"}, toggle_highlights)
  table.insert(lines, "Toggles")
  table.insert(lines, "")
  table.insert(highlights, {})
  table.insert(highlights, {})
  for i=1,#toggles do
    table.insert(lines, aligned_toggles[i])
    local row_highlights = {}
    for j=1,#toggle_highlights[i] do
      for k=1,#toggle_highlights[i][j] do
        table.insert(row_highlights, toggle_highlights[i][j][k])
      end
    end
    table.insert(highlights, row_highlights)
  end

  -- show keybindings

  insert_lines_for_keybindings(lines, highlights, config.keybindings.global_keybindings, global_keybindings_description, "Global", "global")
  insert_lines_for_keybindings(lines, highlights, config.keybindings.waypoint_window_keybindings, waypoint_window_keybindings_description, "Waypoint window", "waypoint window")
  insert_lines_for_keybindings(lines, highlights, config.keybindings.help_keybindings, help_keybindings_description, "Help", "help")

  vim.api.nvim_buf_set_lines(help_bufnr, 0, -1, true, lines)
  -- hlranges is the set of highlight ranges for this line of the help
  for i,hlranges in pairs(highlights) do
    for _,hlrange in pairs(hlranges) do
      vim.api.nvim_buf_set_extmark(help_bufnr, constants.ns, i - 1, hlrange.col_start, {
        end_col = hlrange.col_end,
        hl_group = hlrange.hl_group,
      })
    end
  end
  set_modifiable(help_bufnr, false)
end

local function open_help()
  local is_listed = false
  local is_scratch = false
  help_bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)
  vim.bo[help_bufnr].buftype = "nofile" -- Prevents the buffer from being treated as a normal file
  vim.bo[help_bufnr].bufhidden = "wipe" -- Ensures the buffer is removed when closed
  vim.bo[help_bufnr].swapfile = false   -- Prevents swap file creation
  vim.api.nvim_create_autocmd("WinLeave", {
    group = constants.window_augroup,
    buffer = help_bufnr,
    callback = M.close,
  })

  vim.api.nvim_win_set_buf(winnr, help_bufnr)

  set_help_keybinds()
  draw_help()
  highlight.highlight_custom_groups()
end

-- Function to indent or unindent the current line by 2 spaces
-- if doIndent is true, indent. otherwise unindent
function IndentLine(increment)
  if state.wpi == nil then return end
  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  for _=1, vim.v.count1 do
    local indent = waypoints[state.wpi].indent + increment
    waypoints[state.wpi].indent = u.clamp(
      indent, 0, constants.max_indent
    )
  end
  draw_waypoint_window()
end

function MoveWaypointUp()
  local should_return = (
    #state.waypoints <= 1
    or (state.wpi == 1)
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    vim.notify(sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  for _=1, vim.v.count1 do
    local temp = state.waypoints[state.wpi - 1]
    state.waypoints[state.wpi - 1] = state.waypoints[state.wpi]
    state.waypoints[state.wpi] = temp
    state.wpi = state.wpi - 1
  end
  draw_waypoint_window("swap")
end

function MoveWaypointDown()
  local should_return = (
    #state.waypoints <= 1
    or (state.wpi == #state.waypoints)
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    vim.notify(sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  for _=1, vim.v.count1 do
    local temp = state.waypoints[state.wpi + 1]
    state.waypoints[state.wpi + 1] = state.waypoints[state.wpi]
    state.waypoints[state.wpi] = temp
    state.wpi = state.wpi + 1
  end
  draw_waypoint_window("swap")
end

function MoveWaypointToTop()
  local should_return = (
    #state.waypoints <= 2
    or state.wpi == 1
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    vim.notify(sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  local temp = state.waypoints[state.wpi]
  for i=state.wpi, 2, -1 do
    state.waypoints[i] = state.waypoints[i-1]
  end
  state.waypoints[1] = temp
  state.wpi = 1
  draw_waypoint_window("swap")
end

function MoveWaypointToBottom()
  local should_return = (
    #state.waypoints <= 2
    or state.wpi == #state.waypoints
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    vim.notify(sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  local temp = state.waypoints[state.wpi]
  for i=state.wpi, #state.waypoints - 1 do
    state.waypoints[i] = state.waypoints[i+1]
  end
  state.waypoints[#state.waypoints] = temp
  state.wpi = #state.waypoints
  draw_waypoint_window("swap")
end

function NextWaypoint()
  if state.wpi == nil or state.wpi == #state.waypoints then return end
  for _=1, vim.v.count1 do
    state.wpi = u.clamp(
      state.wpi + 1,
      1,
      #state.waypoints
    )
    -- center on selected waypoint
    state.view.lnum = nil
  end
  if wp_bufnr then
    draw_waypoint_window("move_to_waypoint")
  end
end

function PrevWaypoint()
  if state.wpi == nil or state.wpi == 1 then return end
  for _=1, vim.v.count1 do
    state.wpi = u.clamp(
      state.wpi - 1,
      1,
      #state.waypoints
    )
  end
  if wp_bufnr then
    draw_waypoint_window("move_to_waypoint")
  end
end

function M.GoToCurrentWaypoint()
  if state.wpi == nil then return end

  local waypoint
  if state.sort_by_file_and_line then
    waypoint = state.sorted_waypoints[state.wpi]
  else
    waypoint = state.waypoints[state.wpi]
  end
  assert(waypoint)
  local extmark = uw.extmark_for_waypoint(waypoint)

  if extmark == nil then
    return
  end

  if wp_bufnr then Leave() end

  local waypoint_bufnr = vim.fn.bufnr(waypoint.filepath)
  vim.api.nvim_win_set_buf(0, waypoint_bufnr)
  vim.api.nvim_win_set_cursor(0, { extmark[1] + 1, 0 })
  vim.api.nvim_command("normal! zz")
end

local function clamp_view()
  local width = vim.api.nvim_get_option_value("columns", {})
  local win_width = math.ceil(width * config.window_width)
  local leftcol_max = u.clamp(longest_line_len - win_width, 0)
  state.view.leftcol = u.clamp(state.view.leftcol, 0, leftcol_max)
  state.view.col = u.clamp(state.view.col, state.view.leftcol, state.view.leftcol + win_width - 1)
end

GoToCurrentWaypoint = M.GoToCurrentWaypoint

function M.GoToNextWaypoint()
  NextWaypoint()
  GoToCurrentWaypoint()
end

function M.GoToPrevWaypoint()
  PrevWaypoint()
  GoToCurrentWaypoint()
end

function M.GoToFirstWaypoint()
  if state.wpi == nil then return end
  state.wpi = 1
  GoToCurrentWaypoint()
end

function M.GoToLastWaypoint()
  if state.wpi == nil then return end
  state.wpi = #state.waypoints
  GoToCurrentWaypoint()
end

local function increase_context(increment)
  for _=1, vim.v.count1 do
    state.context = u.clamp(state.context + increment, 0, config.max_context)
    state.view.lnum = nil
  end

  clamp_view()
  draw_waypoint_window("context")
end

function M.increase_context()
  increase_context(1)
end

function M.decrease_context()
  increase_context(-1)
end

local function increase_before_context(increment)
  for _=1, vim.v.count1 do
    state.before_context = u.clamp(state.before_context + increment, 0, config.max_context)
    state.view.lnum = nil
  end

  clamp_view()
  draw_waypoint_window("context")
end

function M.increase_before_context()
  increase_before_context(1)
end

function M.decrease_before_context()
  increase_before_context(-1)
end

local function increase_after_context(increment)
  for _=1, vim.v.count1 do
    state.after_context = u.clamp(state.after_context + increment, 0, config.max_context)
    state.view.lnum = nil
  end

  clamp_view()
  draw_waypoint_window("context")
end

function M.increase_after_context()
  increase_after_context(1)
end

function M.decrease_after_context()
  increase_after_context(-1)
end

function ResetContext()
  state.context = 0
  state.before_context = 0
  state.after_context = 0
  draw_waypoint_window("context")
end

function Scroll(increment)
  local width = vim.api.nvim_get_option_value("columns", {})
  local win_width = math.ceil(width * config.window_width)
  for _=1, vim.v.count1 do
    local leftcol_max = u.clamp(longest_line_len - win_width, 0)
    state.view.leftcol = u.clamp(state.view.leftcol + increment, 0, leftcol_max)
    state.view.col = u.clamp(state.view.col, state.view.leftcol, state.view.leftcol + win_width - 1)
  end
  draw_waypoint_window("scroll")
end

function ResetScroll()
  state.view.col = 0
  state.view.leftcol = 0
  draw_waypoint_window("scroll")
end

function ToggleAnnotation()
  state.show_annotation = not state.show_annotation
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function TogglePath()
  state.show_path = not state.show_path
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function M.toggle_full_path()
  state.show_full_path = not state.show_full_path
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function ToggleLineNum()
  state.show_line_num = not state.show_line_num
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function ToggleFileText()
  state.show_file_text = not state.show_file_text
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function ToggleContext()
  state.show_context = not state.show_context
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function M.toggle_sort()
  local waypoints
  local other_waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
    other_waypoints = state.waypoints
  else
    waypoints = state.waypoints
    other_waypoints = state.sorted_waypoints
  end

  local curr_waypoint = waypoints[state.wpi]
  local new_wpi = nil
  for i, waypoint in ipairs(other_waypoints) do
    if curr_waypoint == waypoint then
      new_wpi = i
    end
  end
  assert(#waypoints == 0 or new_wpi)

  state.wpi = new_wpi
  state.sort_by_file_and_line = not state.sort_by_file_and_line
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window("move_to_waypoint")
  end
end

function ResetCurrentIndent()
  if state.wpi then
    local waypoints
    if state.sort_by_file_and_line then
      waypoints = state.sorted_waypoints
    else
      waypoints = state.waypoints
    end
    waypoints[state.wpi].indent = 0
  end
  draw_waypoint_window()
end

function ResetAllIndent()
  for _,waypoint in pairs(state.waypoints) do
    waypoint.indent = 0
  end
  draw_waypoint_window()
end

function MoveToFirstWaypoint()
  if state.wpi then
    state.wpi = 1
  end
  draw_waypoint_window("move_to_waypoint")
end

function MoveToLastWaypoint()
  if state.wpi then
    state.wpi = #state.waypoints
  end
  draw_waypoint_window("move_to_waypoint")
end

function MoveToOuterWaypoint(draw)
  if state.wpi == nil then return end
  for _=1, vim.v.count1 do
    local current_indent = state.waypoints[state.wpi].indent
    while state.wpi > 1 and state.waypoints[state.wpi].indent >= current_indent do
      state.wpi = state.wpi - 1
    end
  end
  if draw then
    draw_waypoint_window("move_to_waypoint")
  end
end

function MoveToInnerWaypoint(draw)
  if state.wpi == nil then return end
  for _=1, vim.v.count1 do
    local current_indent = state.waypoints[state.wpi].indent
    local i = state.wpi
    while i < #state.waypoints and state.waypoints[i].indent == current_indent do
      i = i + 1
    end
    if state.waypoints[i].indent > current_indent then
      state.wpi = i
    end
  end
  if draw then
    draw_waypoint_window("move_to_waypoint")
  end
end


function M.GoToOuterWaypoint()
  MoveToOuterWaypoint(false)
  GoToCurrentWaypoint()
end

function M.GoToInnerWaypoint()
  MoveToInnerWaypoint(false)
  GoToCurrentWaypoint()
end

function MoveToPrevNeighborWaypoint(draw)
  if state.wpi == nil or state.wpi == 1 then return end
  for _=1, vim.v.count1 do
    local current_indent = state.waypoints[state.wpi].indent
    local i = state.wpi - 1
    while i > 1 and state.waypoints[i].indent > current_indent do
      i = i - 1
    end
    if state.waypoints[i].indent == state.waypoints[state.wpi].indent then
      state.wpi = i
    end
  end
  if draw then
    draw_waypoint_window("move_to_waypoint")
  end
end

function MoveToNextNeighborWaypoint(draw)
  if state.wpi == nil or state.wpi == #state.waypoints then return end
  for _=1, vim.v.count1 do
    local current_indent = state.waypoints[state.wpi].indent
    local i = state.wpi + 1
    while i < #state.waypoints and state.waypoints[i].indent > current_indent do
      i = i + 1
    end
    if state.waypoints[i].indent == state.waypoints[state.wpi].indent then
      state.wpi = i
    end
  end
  if draw then
    draw_waypoint_window("move_to_waypoint")
  end
end

function M.GoToPrevNeighborWaypoint()
  MoveToPrevNeighborWaypoint(false)
  GoToCurrentWaypoint()
end

function M.GoToNextNeighborWaypoint()
  MoveToNextNeighborWaypoint(false)
  GoToCurrentWaypoint()
end

function MoveToPrevTopLevelWaypoint(draw)
  if state.wpi == nil or state.wpi == 1 then return end
  for _=1, vim.v.count1 do
    local i = state.wpi - 1
    while i > 1 and state.waypoints[i].indent > 0 do
      i = i - 1
    end
    if state.waypoints[i].indent == 0 then
      state.wpi = i
    end
  end
  if draw then
    draw_waypoint_window("move_to_waypoint")
  end
end


function MoveToNextTopLevelWaypoint(draw)
  if state.wpi == nil or state.wpi == #state.waypoints then return end
  for _=1, vim.v.count1 do
    local i = state.wpi + 1
    while i < #state.waypoints and state.waypoints[i].indent > 0 do
      i = i + 1
    end
    if state.waypoints[i].indent == 0 then
      state.wpi = i
    end
  end
  if draw then
    draw_waypoint_window("move_to_waypoint")
  end
end

function M.GoToPrevTopLevelWaypoint()
  MoveToPrevTopLevelWaypoint(false)
  GoToCurrentWaypoint()
end

function M.GoToNextTopLevelWaypoint()
  MoveToNextTopLevelWaypoint(false)
  GoToCurrentWaypoint()
end


local function set_waypoint_for_cursor()
  if ignore_next_cursormoved then
    ignore_next_cursormoved = false
    return
  end

  if not line_to_waypoint then return end
  -- use getcursorcharpos to avoid issues with unicode
  local cursor_pos = vim.fn.getcursorcharpos()
  state.view.lnum = cursor_pos[2]
  state.view.col = cursor_pos[3] - 1

  local view = vim.fn.winsaveview()
  state.view.leftcol = view.leftcol
  state.wpi = line_to_waypoint[state.view.lnum]
  draw_waypoint_window("set_waypoint_for_cursor")
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
  draw_waypoint_window()
end

function SetQFList()
  local qflist = {}
  for _,waypoint in pairs(state.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
    local lnum = extmark[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
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

function ToggleHelp()
  if help_bufnr then
    vim.api.nvim_win_set_buf(winnr, wp_bufnr)
    help_bufnr = nil
    draw_waypoint_window()
  else
    open_help()
  end
end


function M.open()
  if is_open then
    return
  else
    is_open = true
  end
  if state.wpi == nil and #state.waypoints > 0 then
    state.wpi = 1
  end

  vim.api.nvim_create_augroup(constants.window_augroup, { clear = true })

  local is_listed = false
  local is_scratch = false
  wp_bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)
  bg_bufnr = vim.api.nvim_create_buf(is_listed, is_scratch)

  vim.bo[wp_bufnr].buftype = "nofile" -- Prevents the buffer from being treated as a normal file
  -- vim.bo[bufnr].bufhidden = "wipe" -- Ensures the buffer is removed when closed
  vim.bo[wp_bufnr].swapfile = false   -- Prevents swap file creation

  -- this extension does not support wrap, all long lines will overflow off the
  -- edge of the screen
  vim.api.nvim_set_option_value('wrap', false, {win = winnr})

  vim.api.nvim_create_autocmd("WinLeave", {
    group = constants.window_augroup,
    buffer = wp_bufnr,
    callback = M.close,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = constants.window_augroup,
    buffer = wp_bufnr,
    callback = set_waypoint_for_cursor,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = constants.window_augroup,
    callback = Resize,
  })

  local win_opts = get_win_opts()
  local bg_win_opts = get_bg_win_opts(win_opts)

  -- Create the background
  bg_winnr = vim.api.nvim_open_win(bg_bufnr, false, bg_win_opts)

  -- Create the window
  winnr = vim.api.nvim_open_win(wp_bufnr, true, win_opts)

  -- account for some color schemes having ridiculous colors for 
  -- the default floating window background.
  if u.hl_background_distance("Normal", "NormalFloat") > 300 then
    vim.api.nvim_set_option_value('winhl', 'NormalFloat:Normal', {win = winnr})
    vim.api.nvim_set_option_value('winhl', 'NormalFloat:Normal', {win = bg_winnr})
  end

  -- I added this because if you open waypoint from telescope, it has wrap enabled
  -- I'm sure there are a bunch of other edge cases like this lurking around
  vim.api.nvim_set_option_value('wrap', false, {win = winnr})

  set_waypoint_keybinds()

  state.view.leftcol = 0
  draw_waypoint_window("move_to_waypoint")
  highlight.highlight_custom_groups()
end

function M.close()
  if not is_open then return end

  -- put this first so we don't call this function again through autocmds by deleting the window
  vim.api.nvim_del_augroup_by_name(constants.window_augroup)

  vim.api.nvim_buf_clear_namespace(wp_bufnr, constants.ns, 0, -1)
  vim.api.nvim_win_close(bg_winnr, true)
  vim.api.nvim_win_close(winnr, true)
  vim.api.nvim_buf_delete(wp_bufnr, {})
  vim.api.nvim_buf_delete(bg_bufnr, {})

  is_open = false
  wp_bufnr = nil
  bg_bufnr = nil
  winnr = nil
  bg_winnr = nil
  help_bufnr = nil
end

function M.clear_state()
  state.load_error       = nil
  state.wpi              = nil
  state.waypoints        = {}
  state.sorted_waypoints = {}

  state.after_context    = 0
  state.before_context   = 0
  state.context          = 0

  state.show_annotation  = true
  state.show_path        = true
  state.show_full_path   = false
  state.show_line_num    = true
  state.show_file_text   = true
  state.show_context     = true

  state.sort_by_file_and_line = false

  state.view = {
    lnum     = nil,
    col      = 0,
    leftcol  = 0,
  }

  os.remove(config.file)
end

function M.clear_state_and_close()
  if is_open then
    M.close()
  end
  M.clear_state()
end

function M.clear_state_and_keep_open()
  M.clear_state()
  set_waypoint_keybinds()
  draw_waypoint_window()
end

function Leave()
  vim.cmd("wincmd w")
end

return M
