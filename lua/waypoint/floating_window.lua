local M = {}

local config = require"waypoint.config"
local crud = require"waypoint.waypoint_crud"
local constants = require"waypoint.constants"
local draw_cache = require"waypoint.draw_cache"
local help_window = require"waypoint.help_window"
local state = require"waypoint.state"
local u = require"waypoint.util"
local uw = require"waypoint.util_waypoint"
local highlight = require"waypoint.highlight"
local message = require"waypoint.message"
local file = require"waypoint.file"
local undo = require"waypoint.undo"

-- these are some pieces of window state that don't belong in the main state
-- table because they shouldn't be persisted to a file
local is_open = false
local wp_bufnr
local bg_bufnr
local help_bufnr
local winnr
local bg_winnr

-- we persist some data about the previous draw in local variables here so that
-- we can access it in autocmd callbacks, and cache results from previous draws
-- where possible.
-- e.g. in CursorMoved:
-- if the user does something to move the cursor to another line, we want to set
-- the new selected waypoint to whatever waypoint the cursor is currently on
local line_to_waypoint

-- vis_cursor means last position of cursor in visual mode
-- vis_v means last position of other side of visual selection
---@type integer?
local vis_cursor_wpi = nil
---@type integer?
local vis_cursor_col = nil
---@type integer?
local vis_cursor_offset = nil

---@type integer?
local vis_v_wpi = nil
---@type integer?
local vis_v_col = nil
---@type integer?
local vis_v_offset = nil

---@type string?
local last_visual_mode = nil

local function keymap_opts(bufnr)
  return {
    noremap = true,
    silent = true,
    nowait = true,
    buffer = bufnr,
  }
end
 ---@enum waypoint.window_actions
M.WINDOW_ACTIONS = {
  context                 = "context",
  exit_visual_mode        = "exit_visual_mode",
  move_to_waypoint        = "move_to_waypoint",
  reselect_visual         = "reselect_visual",
  resize                  = "resize",
  scroll                  = "scroll",
  set_waypoint_for_cursor = "set_waypoint_for_cursor",
  swap                    = "swap",
}

-- I use this to avoid drawing twice when the cursor moves.
-- I have no idea how nvim orders events and event handlers so hopefully this 
-- isn't a catastrophe waiting to happen
--
-- some more stuff I've learned:
-- autocmds don't seem to be multithreaded, but they're not triggered immediately either.
-- When you do something in a lua function (e.g. change the mode), an autocmd
-- event will be put in the queue. when vim gets control back (which will be
-- after you lua function finishes), your callback will be called twice in
-- series with both autocmd events. If you wanted to do something that
-- triggered two autocmds, but ignored both, you would have to do something
-- like this but with an integer flag, and subtract one from the "events to
-- ignore" count. you would subtrack one from the count and early return unless
-- the count is 0.
local ignore_next_cursormoved = false
local ignore_next_modechanged = false
local most_recent_draw_succeeded = true

local function set_modifiable(bufnr, is_modifiable)
  if bufnr == nil then error("Should not be called before initializing window") end
  vim.bo[bufnr].modifiable = is_modifiable
  vim.bo[bufnr].readonly = not is_modifiable
end


local function get_total_width()
  return vim.api.nvim_get_option_value("columns", {})
end

---@return integer
local function status_height()
    local laststatus = vim.opt.laststatus:get()

    if laststatus == 0 then
        return 0 -- Never visible
    elseif laststatus >= 2 then
        return 1 -- Always visible (includes global statusline)
    elseif laststatus == 1 then
        -- Check if there is more than one window in the current tab
        local window_count = #vim.api.nvim_tabpage_list_wins(0)
        return window_count > 1 and 1 or 0
    end

    return 0
end

local function get_total_height()
  local height = vim.api.nvim_get_option_value("lines", {})
  height = height - vim.o.cmdheight
  height = height - status_height()
  return height
end

function M.get_floating_window_width()
  return math.ceil(get_total_width() * config.window_width)
end

function M.get_floating_window_writable_width()
  return math.ceil(get_total_width() * config.window_width) - 4
end

function M.get_floating_window_height()
  return math.ceil(get_total_height() * config.window_height)
end

---@return waypoint.Waypoint?
function M.get_current_waypoint()
  if state.wpi == nil then
    return nil
  end

  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  return waypoints[state.wpi]
end

---@class waypoint.DrawnWaypoints
---@field waypoints waypoint.Waypoint[]
---@field drawn_wpi integer?
---@field drawn_vis_wpi integer?
---@field state_drawn_wpi integer?
---@field state_drawn_vis_wpi integer?
---@field wpi_from_drawn_wpi integer[]

---@param option boolean
---@return string
local function get_toggle_hl(option)
  if option then
    return constants.hl_toggle_on
  end
  return constants.hl_toggle_off
end

---@param split waypoint.DrawnSplit?
---@return vim.api.keyset.win_config, vim.api.keyset.win_config
local function get_win_opts(split)
  split = split or uw.split_by_drawn()
  -- Get editor width and height
  local width = get_total_width()
  local height = get_total_height()

  -- Calculate floating window size
  -- the minus 2 is for the border
  local win_width = math.max(math.ceil(width * config.window_width) - 2, 1)
  local win_height = math.max(math.ceil(height * config.window_height) - 2, 1)

  -- Calculate row and column of upper left corner
  local row = math.floor((height - win_height) / 2) - 1
  local col = math.floor((width - win_width) / 2) - 1

  local bg_win_opts = {
    relative = "editor",
    width    = win_width,
    height   = win_height,
    row      = row,
    col      = col,
    style    = "minimal",
    border   = "rounded",
    title    = {{" Waypoints ", "FloatBorder"}},
  }

  local hpadding = constants.background_window_hpadding
  local vpadding = constants.background_window_vpadding

  local win_opts = {
    relative = "editor",
    width    = math.max(bg_win_opts.width - hpadding * 2, 1),
    height   = math.max(win_height - vpadding * 2, 1),
    row      = bg_win_opts.row + vpadding + 1,
    col      = col + hpadding + 1,
    style    = "minimal",
  }

  local num_drawn_waypoints = #split.drawn

  -- between the A, B, and C indicators
  local sep = {" ─── ", 'FloatBorder' } -- give it the background of the rest of the floating window
  local a = {"A: " .. state.after_context, constants.hl_footer_after_context }
  local b = {"B: " .. state.before_context, constants.hl_footer_before_context }
  local c = {"C: " .. state.context, constants.hl_footer_context }

  -- toggles
  local num =        {"N", get_toggle_hl(state.show_line_num) }
  local path =       {"P", get_toggle_hl(state.show_path) }
  local full_path =  {"F", get_toggle_hl(state.show_full_path) }
  local text =       {"T", get_toggle_hl(state.show_waypoint_text) }
  local context =    {"C", get_toggle_hl(state.show_context) }
  local sort =       {"S", get_toggle_hl(state.sort_by_file_and_line) }

  local wpi_info

  local cursor_i = split.cursor_i
  local cursor_vis_i = split.cursor_vis_i

  if cursor_i == nil then
    wpi_info = {"No waypoints", constants.hl_footer_waypoint_nr}
  elseif split.cursor_vis_i == nil then
    wpi_info = {cursor_i .. '/' .. num_drawn_waypoints, constants.hl_footer_waypoint_nr }
  else
    local lower = math.min(cursor_i, cursor_vis_i)
    local higher = math.max(cursor_i, cursor_vis_i)
    wpi_info = {lower .. "-" .. higher .. '/' .. #state.waypoints, constants.hl_footer_waypoint_nr }
  end
  bg_win_opts.footer = {
    { "─ ", 'FloatBorder'},
    { "Press g? for help", constants.hl_selected },
    sep, a, sep, b, sep, c, sep, wpi_info, sep,
    path, num, text, sep, full_path, context, sort,
    { " ", 'FloatBorder'},
  }

  -- if the footer is two wide for the screen, use a smaller separator
  local footer_length = 0
  for _, item in ipairs(bg_win_opts.footer) do
    footer_length = footer_length + u.vislen(item[1])
  end
  if footer_length > bg_win_opts.width then
    sep[1] = " "
  end

  bg_win_opts.title_pos = "center"
  return win_opts, bg_win_opts
end

---@param action waypoint.window_actions?
---@param reuse ("lines" | "widths")? what to reuse. If widths, don't compute widths in align_waypoint_table. If lines, reuse the content of the waypoint window
local function draw_waypoint_window(action, reuse)
  if not wp_bufnr or not bg_bufnr or not winnr or not bg_winnr then
    M.close()
    return
  end

  set_modifiable(wp_bufnr, true)

  if state.load_error then
    vim.api.nvim_buf_set_lines(wp_bufnr, 0, -1, true, {
      state.load_error,
      "Run " .. constants.command_reset .. " to delete saved waypoints and clear all waypoint state"
    })
    set_modifiable(wp_bufnr, false)
    most_recent_draw_succeeded = false
    return
  end

  if not reuse then
    draw_cache.invalidate_cache()
  end

  -- set this to false at the beginning.
  -- I do this because if the draw fails, then the autocommands usually do too,
  -- which creates a terrible experience where doing anything prints a nasty
  -- error message. this allows the draw calls to fail more gracefully.
  most_recent_draw_succeeded = false

  if state.sort_by_file_and_line and not state.sorted_waypoints then
    uw.make_sorted_waypoints()
  end

  vim.api.nvim_buf_clear_namespace(wp_bufnr, constants.ns, 0, -1)
  -- columns in each line of the waypoint window
  ---@type string[][]
  local table_rows = {}
  ---@type integer[]
  local indents = {}
  ---@type integer[]
  line_to_waypoint = {}

  ---@type integer?
  local cursor_line -- zero indexed
  ---@type integer?
  local cursor_waypoint_topline
  ---@type integer?
  local cursor_waypoint_bottomline

  -- all of these are zero-indexed
  ---@type integer?
  local ctx_start -- one-indexed start line of current waypoint context start
  ---@type integer?
  local ctx_end -- one-indexed start line of current waypoint context end
  ---@type integer?
  local vis_ctx_start -- one-indexed start line of other end of visual selection's waypoint context start
  ---@type integer?
  local vis_ctx_end  -- one-indexed start line of other end of visual selection's waypoint context end

  ---@type (string | waypoint.HighlightRange[])[][]
  ---first index is the line number, second is the column index. each column 
  ---highlight is either a string or a table of highlight ranges. if string, 
  ---highlight the whole column using the group whose name is the string. 
  ---Otherwise, apply each highlight in the table.
  local hlranges = {}

  u.span_start("1")
  local num_lines_before, num_lines_after = uw.num_lines_before_after()

  local split = u.track("split_by_drawn", function() return uw.split_by_drawn() end)
  local drawn = split.drawn
  local cursor_i = split.cursor_i
  local cursor_vis_i = split.cursor_vis_i
  local wpi_from_drawn_i = split.wpi_from_drawn_i

  -- In general, we don't want to be updating state on draw calls, but this simplifies things a lot.
  -- This basically updates the wpi if either the cursor or the vis cursor are on an undrawn waypoint.
  if cursor_i then
    state.wpi = wpi_from_drawn_i[cursor_i]
  end
  if cursor_vis_i then
    state.vis_wpi = wpi_from_drawn_i[cursor_vis_i]
  end

  local winheight = vim.fn.winheight(0)
  local top_view_threshold = nil
  local bottom_view_threshold = nil

  if cursor_i then
    local lines_per_waypoint, space_between = uw.lines_per_waypoint()
    cursor_line = (cursor_i - 1) * (lines_per_waypoint + space_between) + state.before_context + state.context

    -- one-indexed
    local cursor_linenr = cursor_line + 1

    top_view_threshold = cursor_linenr - (winheight - 1)
    bottom_view_threshold = cursor_linenr + (winheight - 1)
  end

  u.span_end("1")
  ---@type waypoint.WaypointContext[]
  local waypoint_contexts = {}

  u.span_start("2")

  for i, waypoint in ipairs(drawn) do
    local waypoint_topline = #table_rows + 1
    local waypoint_bottomline = #table_rows + num_lines_before + 1 + num_lines_after
    local is_in_view = top_view_threshold <= waypoint_bottomline and waypoint_topline <= bottom_view_threshold

    ---@type waypoint.WaypointContext
    local waypoint_context

    if reuse == "lines" and draw_cache.prev_waypoint_contexts then
      waypoint_context = draw_cache.prev_waypoint_contexts[i]
    else
      waypoint_context = u.track("context", function() return uw.get_waypoint_context(
        waypoint,
        num_lines_before,
        num_lines_after,
        is_in_view
      ) end)
      waypoint_contexts[#waypoint_contexts+1] = waypoint_context
    end

    -- TODO
    -- local waypoint_file_text = uw.get_waypoint_context(
    --   waypoint,
    --   num_lines_before,
    --   num_lines_after,
    --   is_in_view
    -- )
    local file_lines = waypoint_context.lines
    local waypoint_linenr = waypoint_context.waypoint_linenr -- zero-indexed
    local context_start_linenr = waypoint_context.context_start_linenr -- zero-indexed
    -- local waypoint_hlranges = waypoint_context.highlight_ranges
    local waypoint_hlranges = uw.get_waypoint_highlights(
      waypoint, waypoint_context, num_lines_before, num_lines_after,
      is_in_view, i, reuse == "lines"
    )
    local file_start_idx = waypoint_context.file_start_idx
    local file_end_idx = waypoint_context.file_end_idx

    if i == cursor_i then
      ctx_start = #table_rows
      cursor_waypoint_topline = #table_rows + 1
      cursor_waypoint_bottomline = #table_rows + #file_lines
      cursor_line = #table_rows + waypoint_linenr
    end
    if i == cursor_vis_i then
      vis_ctx_start = #table_rows
    end

    for j, line_text in ipairs(file_lines) do
      local line_hlranges = {}
      ---@type waypoint.HighlightRange[]
      table.insert(indents, waypoint.indent * config.indent_width)
      table.insert(line_to_waypoint, wpi_from_drawn_i[i])

      -- line in the waypoint window
      ---@type string[]
      local row = {}

      -- waypoint number
      if j == waypoint_linenr + 1 then
        -- if this is line the waypoint is on
        if config.enable_relative_waypoint_numbers then
          if i == cursor_i then
            table.insert(row, tostring(cursor_i))
          else
            table.insert(row, tostring((math.abs(i - cursor_i))))
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
        if j == waypoint_linenr + 1 then
          -- if this is line the waypoint is on
          if state.show_full_path then
            -- if we're showing the full path
            table.insert(row, uw.filepath_from_waypoint(waypoint))
            table.insert(line_hlranges, constants.hl_directory)
          else
            -- if we're just showing the filename
            local filename = vim.fn.fnamemodify(uw.filepath_from_waypoint(waypoint), ":t")
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
        if waypoint.annotation then
          if j == waypoint_linenr + 1 then
            table.insert(row, tostring(waypoint_linenr + 1))
            table.insert(line_hlranges, constants.hl_linenr)
          else
            table.insert(row, "")
            table.insert(line_hlranges, {})
          end
        else
          if j >= file_start_idx and j < file_end_idx then
            table.insert(row, tostring(context_start_linenr + j - file_start_idx))
          else
            table.insert(row, "")
          end
          table.insert(line_hlranges, constants.hl_linenr)
        end
      end

      -- file text
      if state.show_waypoint_text then
        table.insert(row, line_text)
        table.insert(line_hlranges, waypoint_hlranges[j])
      end

      table.insert(table_rows, row)

      table.insert(hlranges, line_hlranges)
    end
    if i == cursor_i then
      ctx_end = #table_rows
    end
    if i == cursor_vis_i then
      vis_ctx_end = #table_rows
    end
    local has_context = state.before_context ~= 0
    has_context = has_context or state.context ~= 0
    has_context = has_context or state.after_context ~= 0
    if state.show_context and has_context and i < #drawn then
      -- insert a blank line as a separator between waypoints
      table.insert(table_rows, "")
      table.insert(indents, 0)
      -- if the user somehow moves to a blank space, just treat that as 
      -- selecting the waypoint above the space
      table.insert(line_to_waypoint, wpi_from_drawn_i[i])
      table.insert(hlranges, {})
    end
  end

  u.span_end("2")
  u.span_start("3")

  assert(#table_rows == #indents, "#rows == " .. #table_rows ..", #indents == " .. #indents .. ", but they should be the same" )
  assert(#table_rows == #line_to_waypoint, "#rows == " .. #table_rows ..", #line_to_waypoint == " .. #line_to_waypoint .. ", but they should be the same" )
  assert(#table_rows == #hlranges, "#rows == " .. #table_rows ..", #hlranges == " .. #hlranges .. ", but they should be the same" )

  u.span_start("3.1")
  local table_cell_types = {"number"}
  if state.show_path then
    table.insert(table_cell_types, "string")
  end
  if state.show_line_num then
    table.insert(table_cell_types, "number")
  end
  if state.show_waypoint_text then
    table.insert(table_cell_types, "string")
  end
  u.span_end("3.1")

  local win_width = M.get_floating_window_width()

  u.span_start("3.2")
  local waypoint_window_lines, widths
  if false and reuse == "lines" and draw_cache.prev_waypoint_window_lines then
    -- u.log("ONE", {
    --     cursor_linenr = cursor_line + 1,
    --     top_view_threshold=top_view_threshold,
    --     bottom_view_threshold=bottom_view_threshold,
    -- })
    -- waypoint_window_lines, widths = draw_cache.prev_waypoint_window_lines, draw_cache.prev_widths
    -- u.span_start("3.hl")
    -- uw.align_waypoint_highlights(
    --   table_rows, table_cell_types, hlranges,
    --   {
    --     column_separator = constants.table_separator,
    --     win_width = win_width,
    --     indents = indents,
    --     width_override=widths,
    --     top_view_threshold=top_view_threshold,
    --     bottom_view_threshold=bottom_view_threshold,
    --   }
    -- )
    -- u.span_end("3.hl")
  else
    -- u.log("TWO", {
    --     cursor_linenr = cursor_line + 1,
    --     top_view_threshold=top_view_threshold,
    --     bottom_view_threshold=bottom_view_threshold,
    --     delta=bottom_view_threshold - top_view_threshold,
    -- })
    ---@type integer[]?
    local width_override = nil
    if (reuse == "widths" or reuse == "lines") and draw_cache.prev_widths then
      width_override = draw_cache.prev_widths
    end
      -- TODO
      -- waypoint_window_lines, widths = uw.align_waypoint_table(
      -- table_rows, table_cell_types, hlranges,
      -- {
      --   column_separator = constants.table_separator,
      --   win_width = win_width,
      --   indents = indents,
      --   width_override=width_override,
      -- })
    u.track("align_waypoint_table", function()
      waypoint_window_lines, widths = uw.align_waypoint_table(
      table_rows, table_cell_types, hlranges,
      {
        column_separator = constants.table_separator,
        win_width = win_width,
        indents = indents,
        width_override=width_override,
        top_view_threshold=top_view_threshold,
        bottom_view_threshold=bottom_view_threshold,
        use_line_cache = reuse == "lines",
      })
    end)
    u.span_start("3.2.1")
    for i, line in pairs(waypoint_window_lines) do
      local is_in_view = top_view_threshold <= i and i <= bottom_view_threshold
      if is_in_view then
        waypoint_window_lines[i] = string.rep(" ", indents[i]) .. line
      end
    end
    u.span_end("3.2.1")
  end
  u.span_end("3.2")

  u.span_start("3.3")
  assert(waypoint_window_lines)

  if action == M.WINDOW_ACTIONS.exit_visual_mode then
    ignore_next_modechanged = true
    u.exit_visual_mode()
  end

  -- save visual mode cursor for use with reselect_visual
  local mode = vim.api.nvim_get_mode().mode
  if u.is_visual(mode) and action ~= M.WINDOW_ACTIONS.reselect_visual then
    last_visual_mode = mode
    local dot_pos = vim.fn.getcharpos('.')
    vis_cursor_wpi    = state.wpi
    vis_cursor_col    = dot_pos[3]
    vis_cursor_offset = dot_pos[4]

    local v_pos = vim.fn.getcharpos('v')
    vis_v_wpi         = state.vis_wpi
    vis_v_col         = v_pos[3]
    vis_cursor_offset = v_pos[4]
  end

  vim.api.nvim_buf_set_lines(wp_bufnr, 0, -1, true, waypoint_window_lines)
  -- if reuse ~= "lines" then
  --   -- Set text in the buffer
  --   vim.api.nvim_buf_set_lines(wp_bufnr, 0, -1, true, waypoint_window_lines)
  -- end
  u.span_end("3.3")
  u.span_end("3")

  u.span_start("4")
  -- highlight the text in the buffer
  for linenr,line_hlranges in ipairs(hlranges) do
    -- skip highlights if they are outside our view 
    if top_view_threshold and top_view_threshold <= linenr and linenr <= bottom_view_threshold then
      for _,col_highlights in ipairs(line_hlranges) do
        if type(col_highlights) == "string" then
          assert(false, "This should not happen, align_waypoint_table should change all column-wide highlights to a HighlightRange")
        else
          for i,hlrange in ipairs(col_highlights) do
            vim.api.nvim_buf_set_extmark(wp_bufnr, constants.ns, linenr - 1, hlrange.col_start + indents[linenr], {
              end_col = hlrange.col_end + indents[linenr], -- 0-based exclusive column upper bound is the same as 1 based inclusive
              hl_group = hlrange.hl_group,                 -- Highlight group to apply
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
            --   linenr - 1,
            --   hlrange.col_start,
            --   hlrange.col_end
            -- )
          end
        end
      end
    end
  end

  u.span_end("4")
  u.span_start("5")

  local waypoint_context_lines = (state.before_context + state.context + 1 + state.context + state.after_context)
  if (cursor_i) then
    assert(ctx_start)
    assert(ctx_end)
    assert(cursor_line)
    assert(cursor_waypoint_topline)
    assert(cursor_waypoint_bottomline)
    if action == M.WINDOW_ACTIONS.reselect_visual then
      local has_spacer = u.any({
        state.before_context > 0,
        state.after_context > 0,
        state.context > 0,
      })
      if has_spacer then
        waypoint_context_lines = waypoint_context_lines + 1
      end
      local vis_v_line      = (waypoint_context_lines) * (cursor_vis_i - 1) + state.before_context + state.context + 1
      local vis_cursor_line = (waypoint_context_lines) * (cursor_i     - 1) + state.before_context + state.context + 1

      -- note that this doesn't really handle virtual columns, just char indexes.
      -- I figured this wasn't that important to add since the cursor will jump anyway.
      -- It's easier to code this way because virtual col can only be set with vim.cmd.normal and |
      u.switch_visual()
      vim.fn.setcharpos('.', { 0, vis_cursor_line, vis_cursor_col, vis_cursor_offset })
      u.switch_visual()
      vim.fn.setcharpos('.', { 0, vis_v_line,      vis_v_col,      vis_v_offset      })
      u.switch_visual()
    end

    -- if in visual mode, set the visual range. this is important because
    -- increasing/decreasing the context while in visual mode causes the visual
    -- mode to be in the wrong place. We need to do this before calling 
    if cursor_vis_i then
      assert(ctx_start)
      assert(vis_ctx_start)
      assert(ctx_end)
      assert(vis_ctx_end)
      local cursor_start_line = math.min(
        ctx_start,
        vis_ctx_start
      ) + 1 + num_lines_before

      local cursor_end_line = math.max(
        ctx_end,
        vis_ctx_end
      ) - num_lines_after

      do
        local vis_cursor_line
        local wpi_cursor_line
        if cursor_i < cursor_vis_i then
          wpi_cursor_line = cursor_start_line
          vis_cursor_line = cursor_end_line
        else
          wpi_cursor_line = cursor_end_line
          vis_cursor_line = cursor_start_line
        end
        local cursor
        local cursor_col
        local cursor_offset

        u.switch_visual()
        cursor = vim.fn.getcharpos('.')
        cursor_col    = cursor[3]
        cursor_offset = cursor[4]
        vim.fn.setcharpos('.', { 0, vis_cursor_line, cursor_col, cursor_offset })

        u.switch_visual()
        cursor = vim.fn.getcharpos('.')
        cursor_col    = cursor[3]
        cursor_offset = cursor[4]
        vim.fn.setcharpos('.', { 0, wpi_cursor_line, cursor_col, cursor_offset })
      end
    end

    if action == M.WINDOW_ACTIONS.context then
      -- move to the current waypoint's line and center the screen
      u.goto_line(cursor_line + 1)
      vim.api.nvim_command("normal! zz")
    elseif action == M.WINDOW_ACTIONS.exit_visual_mode then
      u.goto_line(cursor_line + 1)
    elseif action == M.WINDOW_ACTIONS.move_to_waypoint then
      u.goto_line(cursor_line + 1)
    elseif action == M.WINDOW_ACTIONS.reselect_visual then
      -- do nothing
    elseif action == M.WINDOW_ACTIONS.resize then
      u.goto_line(cursor_line + 1)
    elseif action == M.WINDOW_ACTIONS.scroll then
      -- do nothing
    elseif action == M.WINDOW_ACTIONS.set_waypoint_for_cursor then
      -- do nothing
    elseif action == M.WINDOW_ACTIONS.swap then
      u.goto_line(cursor_line + 1)
    end

    -- if need be, scroll up/down to make the whole waypoint context visible.
    -- have to re-get the view because it could change after setting the lines in the waypoint buffer
    local view = vim.fn.winsaveview()
    if waypoint_context_lines >= winheight then
      -- vim.api.nvim_command("normal! zz")
      -- since we limit context size depending on window height, this should only happen when the context fills up the whole window
      view.topline = cursor_waypoint_topline
      vim.fn.winrestview(view)
    elseif view.topline > cursor_waypoint_topline then
      view.topline = cursor_waypoint_topline
      vim.fn.winrestview(view)
    elseif view.topline + winheight - 1 < cursor_waypoint_bottomline then
      view.topline = cursor_waypoint_bottomline - winheight + 1
      vim.fn.winrestview(view)
    end

    -- if we're in visual mode, highlight visual selection.
    -- otherwise, highlight current waypoint with constants.hl_selected
    if cursor_vis_i then
      local highlight_start = math.min(
        ctx_start,
        vis_ctx_start
      )
      local highlight_end = math.max(
        ctx_end,
        vis_ctx_end
      )
      -- highlight visual selection
      for i=highlight_start,highlight_end-1 do
        vim.hl.range(wp_bufnr, constants.ns, "Visual", {i, 0}, {i, -1})
      end
    else
      -- highlight current waypoint
      for i=ctx_start,ctx_end-1 do
        vim.hl.range(wp_bufnr, constants.ns, constants.hl_selected, {i, 0}, {i, -1})
      end
    end
  end

  u.span_end("5")
  u.span_start("6")

  -- update window config, used to update the footer a/b/c indicators and the size of the window
  local win_opts, bg_win_opts = get_win_opts(split)
  vim.api.nvim_win_set_config(winnr, win_opts)
  vim.api.nvim_win_set_config(bg_winnr, bg_win_opts)

  set_modifiable(wp_bufnr, false)
  if action ~= M.WINDOW_ACTIONS.set_waypoint_for_cursor then
    ignore_next_cursormoved = true
  end

  draw_cache.prev_widths = widths
  -- if we reuse lines, we don't touch the variable, so don't set this
  if reuse ~= "lines" then
    draw_cache.prev_waypoint_contexts = waypoint_contexts
  end
  draw_cache.prev_waypoint_window_lines = waypoint_window_lines
  most_recent_draw_succeeded = true

  u.span_end("6")
end

---@type table<integer, table<string, boolean>>
M.bound_keys = {}

-- binds the keybinding (or keybindings) to the given action 
---@param keybindings table<string, waypoint.Keybinding>
---@param modes string[]
---@param action string
---@param fn string | function the vim mapping string that this keybind should perform
local function bind_key(bufnr, modes, keybindings, action, fn)
  if not keybindings[action] then
    error(action .. " is not a key in the provided keybindings table")
  end
  local keybinding = keybindings[action]
  if type(keybinding) == "string" then
    vim.keymap.set(modes, keybinding, fn, keymap_opts(bufnr))
  elseif type(keybinding) == "table" then
    for i, v in ipairs(keybinding) do
      if type(v) ~= "string" then
        error("Type of element " .. i .. " of keybinding should be string, but was " .. type(v) .. ".")
      end
      vim.keymap.set(modes, v, fn, keymap_opts(bufnr))
    end
  else
    error("Type of param keybinding should be string or table, but was " .. type(keybinding) .. ".")
  end
  M.bound_keys[bufnr] = (M.bound_keys[bufnr] or {})
  M.bound_keys[bufnr][action] = true
end

-- shared between the help buffer and the waypoint buffer
local function set_shared_keybinds(bufnr)
  bind_key(bufnr, { 'n' }, config.keybindings.waypoint_window_keybindings, "exit_waypoint_window",    M.leave)

  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "increase_context",        M.increase_context)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "decrease_context",        M.decrease_context)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "increase_before_context", M.increase_before_context)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "decrease_before_context", M.decrease_before_context)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "increase_after_context",  M.increase_after_context)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "decrease_after_context",  M.decrease_after_context)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "reset_context",           M.reset_context)

  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "toggle_path",             M.toggle_path)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "toggle_full_path",        M.toggle_full_path)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "toggle_line_num",         M.toggle_line_number)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "toggle_file_text",        M.toggle_text)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "toggle_context",          M.toggle_context)
  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "toggle_sort",             M.toggle_sort)

  bind_key(bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "set_quickfix_list",       M.set_quickfix_list)
end

local function set_help_keybinds()
  set_shared_keybinds(help_bufnr)
  bind_key(help_bufnr, { 'n' }, config.keybindings.help_keybindings, "exit_help", M.toggle_help)
end

local function set_waypoint_keybinds()
  set_shared_keybinds(wp_bufnr)

  bind_key(wp_bufnr, { 'n' }, config.keybindings.waypoint_window_keybindings, "show_help",            M.toggle_help)
  bind_key(wp_bufnr, { 'n' }, config.keybindings.waypoint_window_keybindings, "exit_waypoint_window", M.leave)

  if state.load_error then
    vim.keymap.set('n', '<CR>', M.clear_state, keymap_opts(wp_bufnr))
    return
  end

  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "indent",                  M.indent)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "unindent",                M.unindent)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "reset_waypoint_indent",   M.reset_current_indent)
  bind_key(wp_bufnr, { 'n' },      config.keybindings.waypoint_window_keybindings, "reset_all_indent",        M.reset_all_indent)

  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "prev_waypoint",           M.prev_waypoint)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "next_waypoint",           M.next_waypoint)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "first_waypoint",          M.move_to_first_waypoint)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "last_waypoint",           M.move_to_last_waypoint)

  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "move_waypoint_up",        M.move_waypoint_up)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "move_waypoint_down",      M.move_waypoint_down)
  bind_key(wp_bufnr, { 'n' },      config.keybindings.waypoint_window_keybindings, "jump_to_waypoint",        M.jump_to_waypoint)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "move_waypoint_to_top",    M.move_waypoint_to_top)
  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "move_waypoint_to_bottom", M.move_waypoint_to_bottom)

  bind_key(wp_bufnr, { 'n', 'v' }, config.keybindings.waypoint_window_keybindings, "delete_waypoint",         M.delete)
  bind_key(wp_bufnr, { 'n' },      config.keybindings.waypoint_window_keybindings, "move_waypoints_to_file",  M.move_waypoints_to_file_wrapper)

  bind_key(wp_bufnr, { 'n' },      config.keybindings.waypoint_window_keybindings, "undo",                    M.undo)
  bind_key(wp_bufnr, { 'n' },      config.keybindings.waypoint_window_keybindings, "redo",                    M.redo)

  bind_key(wp_bufnr, { 'n' },      config.keybindings.waypoint_window_keybindings, "reselect_visual",         M.reselect_visual)
end

local function draw_help()
  set_modifiable(help_bufnr, true)
  local lines, highlights = help_window.get_help_window_lines()

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

  vim.wo[winnr].winfixbuf = false
  vim.api.nvim_win_set_buf(winnr, help_bufnr)
  vim.wo[winnr].winfixbuf = true

  set_help_keybinds()
  draw_help()
  highlight.highlight_custom_groups()
end

function M.indent()
  crud.indent(1)
  draw_waypoint_window()
  vim.cmd.normal("m.")
end

function M.unindent()
  crud.indent(-1)
  draw_waypoint_window()
  vim.cmd.normal("m.")
end

function M.move_waypoint_up()
  crud.move_waypoints(-1)
  draw_waypoint_window(M.WINDOW_ACTIONS.swap, "widths")
  vim.cmd.normal("m.")
end

function M.move_waypoint_down()
  crud.move_waypoints(1)
  draw_waypoint_window(M.WINDOW_ACTIONS.swap, "widths")
  vim.cmd.normal("m.")
end

function M.move_waypoint_to_top()
  crud.move_waypoint_to_top()
  draw_waypoint_window(M.WINDOW_ACTIONS.swap, "widths")
  vim.cmd.normal("m.")
end

function M.move_waypoint_to_bottom()
  crud.move_waypoint_to_bottom()
  draw_waypoint_window(M.WINDOW_ACTIONS.swap, "widths")
  vim.cmd.normal("m.")
end

function M.undo()
  undo.undo()
  draw_waypoint_window(M.WINDOW_ACTIONS.move_to_waypoint)
  vim.cmd.normal("m.")
end

function M.redo()
  undo.redo()
  draw_waypoint_window(M.WINDOW_ACTIONS.move_to_waypoint)
  vim.cmd.normal("m.")
end

function M.reselect_visual()
  if u.is_visual(vim.api.nvim_get_mode().mode) then
    return
  end
  if last_visual_mode then
    assert(vis_cursor_wpi)
    assert(vis_cursor_col)
    assert(vis_v_wpi)
    assert(vis_v_col)

    state.wpi = u.clamp(vis_cursor_wpi, 1, #state.waypoints)
    state.vis_wpi = u.clamp(vis_v_wpi, 1, #state.waypoints)

    ignore_next_modechanged = true
    vim.cmd.normal(last_visual_mode)

    draw_waypoint_window(M.WINDOW_ACTIONS.reselect_visual, "lines")
  else
    state.vis_wpi = state.wpi

    ignore_next_modechanged = true
    vim.cmd.normal("v")

    draw_waypoint_window(nil, "lines")
  end
end

function M.next_waypoint()
  if state.wpi == nil or state.wpi == #state.waypoints then return end

  ---@type waypoint.Waypoint[]
  local waypoints

  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  local count = 0
  local selection_top, selection_bottom, _, bottom = uw.get_drawn_wpi()
  if state.vis_wpi then
    if state.wpi < state.vis_wpi then
      state.wpi = selection_top
    else
      state.wpi = selection_bottom
    end
  else
    state.wpi = selection_top
  end
  if state.wpi and bottom then
    while state.wpi < bottom and count < vim.v.count1 do
      state.wpi = state.wpi + 1
      local wp = waypoints[state.wpi]
      if uw.should_draw_waypoint(wp) then
        count = count + 1
      end
    end
    if wp_bufnr then
      draw_waypoint_window(M.WINDOW_ACTIONS.move_to_waypoint, "lines")
    end
  end
end

function M.prev_waypoint()
  if state.wpi == nil or state.wpi == 1 then return end

  ---@type waypoint.Waypoint[]
  local waypoints

  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  local count = 0
  local selection_top, selection_bottom, top, _ = uw.get_drawn_wpi()
  if state.vis_wpi then
    if state.wpi < state.vis_wpi then
      state.wpi = selection_top
    else
      state.wpi = selection_bottom
    end
  else
    state.wpi = selection_top
  end
  if state.wpi and top then
    while state.wpi and top and state.wpi > top and count < vim.v.count1 do
      state.wpi = state.wpi - 1
      local wp = waypoints[state.wpi]
      if uw.should_draw_waypoint(wp) then
        count = count + 1
      end
    end
    if wp_bufnr then
      draw_waypoint_window(M.WINDOW_ACTIONS.move_to_waypoint, "lines")
    end
  end
end

function M.jump_to_waypoint()
  if state.wpi == nil then return end

  local waypoint
  if state.sort_by_file_and_line then
    waypoint = state.sorted_waypoints[state.wpi]
  else
    waypoint = state.waypoints[state.wpi]
  end
  assert(waypoint)
  if waypoint.bufnr == -1 or 0 == vim.fn.bufloaded(waypoint.bufnr) then
    message.notify(message.missing_file_err_msg, vim.log.levels.ERROR)
    return
  end

  local extmark = uw.extmark_from_waypoint(waypoint)
  if not extmark then
    message.notify(constants.error_line_oob, vim.log.levels.ERROR)
    return
  end

  if extmark == nil then
    return
  end

  if wp_bufnr then M.leave() end

  local waypoint_bufnr = uw.bufnr_from_waypoint(waypoint)
  vim.api.nvim_win_set_buf(0, waypoint_bufnr)
  vim.api.nvim_win_set_cursor(0, { extmark[1], 0 })
  vim.api.nvim_command("normal! zz")
end

local function reduce_context_to_fit_window()
  assert(is_open)
  local winheight = vim.fn.winheight(0)
  local total_context = state.before_context + state.context + 1 + state.context + state.after_context
  local factor = winheight / total_context
  if factor < 1.0 then
    state.before_context = math.floor(state.before_context * factor)
    state.context = math.floor(state.context * factor)
    state.after_context = math.floor(state.after_context * factor)
  end
  total_context = state.before_context + state.context + 1 + state.context + state.after_context
  assert(total_context <= winheight)
end

local function increase_context(increment)
  assert(is_open)
  local winheight = vim.fn.winheight(0)
  local max_context = math.floor((winheight - state.before_context - 1 - state.after_context) / 2)
  for _=1, vim.v.count1 do
    state.context = u.clamp(state.context + increment, 0, max_context)
  end

  draw_waypoint_window(M.WINDOW_ACTIONS.context)
end

function M.increase_context()
  increase_context(1)
end

function M.decrease_context()
  increase_context(-1)
end

local function increase_before_context(increment)
  assert(is_open)
  local winheight = vim.fn.winheight(0)
  local max_before_context = math.floor(winheight - state.context - 1 - state.context - state.after_context)
  for _=1, vim.v.count1 do
    state.before_context = u.clamp(state.before_context + increment, 0, max_before_context)
  end
  draw_waypoint_window(M.WINDOW_ACTIONS.context)
end

function M.increase_before_context()
  increase_before_context(1)
end

function M.decrease_before_context()
  increase_before_context(-1)
end

local function increase_after_context(increment)
  assert(is_open)
  local winheight = vim.fn.winheight(0)
  local max_after_context = math.floor(winheight - state.before_context - state.context - 1 - state.context)
  for _=1, vim.v.count1 do
    state.after_context = u.clamp(state.after_context + increment, 0, max_after_context)
  end

  draw_waypoint_window(M.WINDOW_ACTIONS.context)
end

function M.increase_after_context()
  increase_after_context(1)
end

function M.decrease_after_context()
  increase_after_context(-1)
end

function M.reset_context()
  state.context = 0
  state.before_context = 0
  state.after_context = 0
  draw_waypoint_window(M.WINDOW_ACTIONS.context)
end

function M.toggle_path()
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

function M.toggle_line_number()
  state.show_line_num = not state.show_line_num
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function M.toggle_text()
  state.show_waypoint_text = not state.show_waypoint_text
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window()
  end
end

function M.toggle_context()
  state.show_context = not state.show_context
  if help_bufnr then
    draw_help()
  else
    draw_waypoint_window(M.WINDOW_ACTIONS.context)
  end
end

function M.toggle_sort()
  local waypoints
  local other_waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
    other_waypoints = state.waypoints
  else
    -- since we haven't toggled yet, we'll need to create sorted waypoints if
    -- sort is not currently enabled
    if not state.sorted_waypoints then
      uw.make_sorted_waypoints()
    end
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
    draw_waypoint_window(M.WINDOW_ACTIONS.move_to_waypoint, "widths")
  end
end

function M.reset_current_indent()
  crud.reset_current_indent()
  draw_waypoint_window()
  vim.cmd.normal("m.")
end

function M.reset_all_indent()
  crud.reset_all_indent()
  draw_waypoint_window()
  vim.cmd.normal("m.")
end

function M.move_to_first_waypoint()
  _, _, state.wpi, _ = uw.get_drawn_wpi()
  draw_waypoint_window(M.WINDOW_ACTIONS.move_to_waypoint, "lines")
end

function M.move_to_last_waypoint()
  _, _, _, state.wpi = uw.get_drawn_wpi()
  draw_waypoint_window(M.WINDOW_ACTIONS.move_to_waypoint, "lines")
end

---@param source_file_path string
---@param dest_file_path string
---@param allow_same_file boolean?
---@return boolean # if the move was successful
function M.move_waypoints_to_file(source_file_path, dest_file_path, allow_same_file)
  if not allow_same_file and source_file_path == dest_file_path then
    message.notify(message.files_same(source_file_path), vim.log.levels.ERROR)
    return false
  end
  if not u.file_exists(dest_file_path) then
    message.notify(message.file_dne(dest_file_path), vim.log.levels.ERROR)
    return false
  end
  ---@type integer[]
  -- indices of waypoints in the file
  local wpis_in_file = {}
  source_file_path = vim.fs.normalize(source_file_path)
  ---@type integer?
  local change_wpi = nil
  for i,waypoint in pairs(state.waypoints) do
    if uw.filepath_from_waypoint(waypoint) == source_file_path then
      if not change_wpi then
        change_wpi = i
      end
      table.insert(wpis_in_file, i)
    end
  end
  if #wpis_in_file == 0 then
    -- message.notify(message.no_waypoints_in_file(source_file_path), vim.log.levels.ERROR)
    return false
  end

  file.locate_waypoints_in_file(source_file_path, dest_file_path, wpis_in_file, change_wpi)
  message.notify(message.moved_waypoints_to_file(#wpis_in_file, source_file_path, dest_file_path), vim.log.levels.INFO)

  draw_waypoint_window()
  vim.cmd.normal('m.')
  return true
end

---@param opts vim.api.keyset.create_user_command.command_args
function M.move_waypoints_to_file_command(opts)
  local new_file = opts.args
  local waypoint = M.get_current_waypoint()
  if waypoint == nil then
    message.notify("No current waypoint")
    return
  end
  M.move_waypoints_to_file(uw.filepath_from_waypoint(waypoint), new_file)
end

function M.move_waypoints_to_file_wrapper()
  local has_telescope, _ = pcall(require, "telescope")
  local waypoint = M.get_current_waypoint()
  if waypoint == nil then
    message.notify("No currently selected waypoint", vim.log.levels.ERROR)
    return
  end

  if not has_telescope then
    vim.fn.feedkeys(':MoveWaypointsToFile ', 'n')
  else
    local builtin = require('telescope.builtin')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    builtin.find_files({
      prompt_title = "Move waypoints to file",
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local selected_file = selection.path or selection[1]
          local path = vim.fn.fnamemodify(selected_file, ":.")

          local filepath = uw.filepath_from_waypoint(waypoint)

          local choice = vim.fn.confirm(
            "Move waypoints?\nfrom: " ..
            filepath ..
            "\nto:   " .. path, "&yes\n&no", 2
          )

          if choice == 1 then
            M.open()
            M.move_waypoints_to_file(filepath, path)
          end
        end)
        return true
      end,
    })
  end
end

-- override_ignore is used to make sure this gets called during tests, where the
-- autocmd normally doesn't trigger until the test is over, and so has to be
-- triggered manually.
---@param _ any
---@param override_ignore boolean?
function M.set_waypoint_for_cursor(_, override_ignore)
  assert(is_open)
  local should_ignore = u.any({
    not most_recent_draw_succeeded,
    not override_ignore and u.any{
      ignore_next_cursormoved,
      state.should_ignore_autocmds,
    }
  })
  u.log("IGNORE SET WP", should_ignore)
  if should_ignore then
    ignore_next_cursormoved = false
    return
  end

  if not line_to_waypoint then return end
  local lnum = vim.fn.getpos(".")[2]
  local cursor_wpi = line_to_waypoint[lnum]
  if state.vis_wpi then
      -- covers the case when the user switches to the other end of the visual selection with "o".
    local vis_lnum = vim.fn.getpos("v")[2]
    local vis_wpi = line_to_waypoint[vis_lnum]
    local should_swap_wpi = u.all{
      cursor_wpi ~= vis_wpi,
      (state.wpi < state.vis_wpi) ~= (lnum < vis_lnum),
    }
    if should_swap_wpi then
      state.vis_wpi = state.wpi
    end
  end
  state.wpi = cursor_wpi
  draw_waypoint_window(nil, "lines")
end

function M.resize(_)
  local win_opts, bg_win_opts = get_win_opts()
  vim.api.nvim_win_set_config(winnr, win_opts)
  vim.api.nvim_win_set_config(bg_winnr, bg_win_opts)
  reduce_context_to_fit_window()
  ignore_next_cursormoved = true
  draw_waypoint_window(M.WINDOW_ACTIONS.context)
end

function M.delete()
  crud.delete_curr()
  local action
  if u.is_in_visual_mode() then
    action = M.WINDOW_ACTIONS.exit_visual_mode
  else
    action = nil
  end
  draw_waypoint_window(action)
  vim.cmd.normal("m.")
end

function M.set_quickfix_list()
  local qflist = {}
  for _,waypoint in pairs(state.waypoints) do
    local bufnr = waypoint.bufnr or vim.fn.bufnr(waypoint.filepath)
    local filepath = waypoint.filepath or u.path_from_buf(bufnr)
    local extmark = uw.buf_get_extmark(bufnr, waypoint.extmark_id)
    if extmark then
      local lnum = extmark[1]
      local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
      table.insert(qflist, {
        filename = filepath,
        lnum = lnum,
        col = 0,
        text = line,
      })
    end
  end
  vim.fn.setqflist(qflist, 'r')
  vim.cmd('copen')
end

function M.toggle_help()
  if help_bufnr then
    vim.wo[winnr].winfixbuf = false
    vim.api.nvim_win_set_buf(winnr, wp_bufnr)
    vim.wo[winnr].winfixbuf = true
    help_bufnr = nil
    draw_waypoint_window()
  else
    open_help()
  end
end

---@param arg table?
---@param override_arg table?
function M.on_mode_change(arg, override_arg)
  assert(is_open)
  arg = override_arg or arg
  assert(arg)
  local should_ignore = u.any({
    -- state.should_ignore_autocmds,
    not most_recent_draw_succeeded,
    override_arg == nil and u.any{
      ignore_next_modechanged,
      state.should_ignore_autocmds,
    }
  })
  if should_ignore then
    ignore_next_modechanged = false
    return
  end
  if override_arg == true then
    arg = {match="n:v"}
  end
  assert(line_to_waypoint)
  local modes = vim.split(arg.match, ":")
  assert(#modes == 2)
  local old_mode = modes[1]
  local new_mode = modes[2]
  local old_is_visual = u.is_visual(old_mode)
  local new_is_visual = u.is_visual(new_mode)

  if old_is_visual and not new_is_visual then
    state.vis_wpi = nil
  elseif not old_is_visual and new_is_visual then
    state.vis_wpi = state.wpi
  end
  draw_waypoint_window(nil, "lines")
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
    callback = M.set_waypoint_for_cursor,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = constants.window_augroup,
    callback = M.resize,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = constants.window_augroup,
    callback = M.on_mode_change,
  })

  local win_opts, bg_win_opts = get_win_opts()

  -- Create the background
  bg_winnr = vim.api.nvim_open_win(bg_bufnr, false, bg_win_opts)

  -- Create the window
  winnr = vim.api.nvim_open_win(wp_bufnr, true, win_opts)

  vim.wo[winnr].winfixbuf = true
  vim.wo[bg_winnr].winfixbuf = true

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

  draw_waypoint_window("move_to_waypoint")
  highlight.highlight_custom_groups()
end

function M.close()
  if not is_open then return end
  M.bound_keys = {}

  -- put this first so we don't call this function again through autocmds by deleting the window
  vim.api.nvim_del_augroup_by_name(constants.window_augroup)

  -- ideally all of these should be non-nil, but this helps with catching cases where something has gone wrong and recovering gracefully
  if bg_winnr then
    vim.api.nvim_win_close(bg_winnr, true)
  end
  if winnr then
    vim.api.nvim_win_close(winnr, true)
  end
  if wp_bufnr then
    vim.api.nvim_buf_clear_namespace(wp_bufnr, constants.ns, 0, -1)
    vim.api.nvim_buf_delete(wp_bufnr, {})
  end
  if bg_bufnr then
    vim.api.nvim_buf_delete(bg_bufnr, {})
  end

  is_open = false
  wp_bufnr = nil
  bg_bufnr = nil
  winnr = nil
  bg_winnr = nil
  help_bufnr = nil
end

function M.clear_state()
  for k,_ in pairs(state) do
    state[k] = nil
  end

  state.load_error       = nil
  state.wpi              = nil
  state.vis_wpi          = nil
  state.waypoints        = {}
  state.sorted_waypoints = {}

  state.after_context    = 0
  state.before_context   = 0
  state.context          = 0

  state.show_path        = true
  state.show_full_path   = false
  state.show_line_num    = true
  state.show_waypoint_text   = true
  state.show_context     = true

  state.sort_by_file_and_line = false

  state.should_notify = true
end

function M.clear_extmarks()
  local bufs = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(bufs) do
    vim.api.nvim_buf_clear_namespace(bufnr, constants.ns, 0, -1)
  end
end

function M.clear_and_close()
  if is_open then
    M.close()
  end
  M.clear()
end

function M.clear_state_with_confirmation()
  local choice = vim.fn.confirm(
    "Clear all state? This will delete your waypoints", "&yes\n&no", 2
  )

  if choice == 1 then
    if is_open then
      M.clear_and_keep_open()
    else
      M.clear()
    end
  end
end

function M.clear()
  M.clear_state()
  M.clear_extmarks()
  undo.clear()
  os.remove(config.file)
end


function M.clear_and_keep_open()
  M.clear()
  set_waypoint_keybinds()
  draw_waypoint_window()
end

function M.leave()
  vim.cmd("wincmd w")
end

function M.get_bufnr()
  return wp_bufnr
end

function M.get_help_bufnr()
  return help_bufnr
end

function M.is_open()
  return is_open
end

return M
