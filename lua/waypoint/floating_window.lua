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

local keymap_opts = {
  noremap = true,
  silent = true,
  nowait = true,
}

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
  set_modifiable(wp_bufnr, true)
  vim.api.nvim_buf_clear_namespace(wp_bufnr, constants.ns, 0, -1)
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

  local num_lines_before
  local num_lines_after
  if state.show_context then
    num_lines_before = state.before_context + state.context
    num_lines_after = state.after_context + state.context
  else
    num_lines_before = 0
    num_lines_after = 0
  end

  for i, waypoint in ipairs(state.waypoints) do
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
    assert(extmark_lines)

    if i == state.wpi then
      highlight_start = #rows
      waypoint_topline = #rows + 1
      waypoint_bottomline = #rows + #extmark_lines
      cursor_line = #rows + extmark_line
    end

    for j, line_text in ipairs(extmark_lines) do
      local line_hlranges = {}
      --- @type table<waypoint.HighlightRange>
      local line_extmark_hlranges = extmark_hlranges[j]
      table.insert(indents, waypoint.indent * config.indent_width)
      table.insert(line_to_waypoint, i)
      local row = {}

      -- waypoint number
      if j == extmark_line + 1 then
        -- if this is line the waypoint is on
        table.insert(row, tostring(i))
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
        table.insert(row, tostring(context_start_linenr + j))
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
    if state.show_context and has_context and i < #state.waypoints then
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
  local aligned = uw.align_waypoint_table(rows, table_cell_types, hlranges, true, win_width)

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
    if action == "move_to_waypoint" or action == "context" or action == "swap" then
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
      vim.api.nvim_buf_add_highlight(wp_bufnr, 0, constants.hl_selected, i, 0, -1)
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

-- shared between the help buffer and the waypoint buffer
local function set_shared_keybinds(bufnr)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'mf',    ":lua Leave()<CR>",                            keymap_opts)

  vim.api.nvim_buf_set_keymap(bufnr, "n", "c",     ":<C-u>lua IncreaseContext(1)<CR>",            keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "C",     ":<C-u>lua IncreaseContext(-1)<CR>",           keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "b",     ":<C-u>lua IncreaseBeforeContext(1)<CR>",      keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "B",     ":<C-u>lua IncreaseBeforeContext(-1)<CR>",     keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "a",     ":<C-u>lua IncreaseAfterContext(1)<CR>",       keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "A",     ":<C-u>lua IncreaseAfterContext(-1)<CR>",      keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "R",     ":<C-u>lua ResetContext()<CR>",                keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "rc",    ":<C-u>lua ResetContext()<CR>",                keymap_opts)

  vim.api.nvim_buf_set_keymap(bufnr, "n", "ta",    ":lua ToggleAnnotation()<CR>",                 keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tp",    ":lua TogglePath()<CR>",                       keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tf",    ":lua ToggleFullPath()<CR>",                   keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tl",    ":lua ToggleLineNum()<CR>",                    keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tn",    ":lua ToggleLineNum()<CR>",                    keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tt",    ":lua ToggleFileText()<CR>",                   keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "tc",    ":lua ToggleContext()<CR>",                    keymap_opts)

  vim.api.nvim_buf_set_keymap(bufnr, "n", "Q",     ":<C-u>lua SetQFList()<CR>",                   keymap_opts)
end

local function set_help_keybinds()
  set_shared_keybinds(help_bufnr)

  vim.api.nvim_buf_set_keymap(help_bufnr, 'n', 'q',     ":lua ToggleHelp()<CR>",                  keymap_opts)
  vim.api.nvim_buf_set_keymap(help_bufnr, 'n', '<esc>', ":lua ToggleHelp()<CR>",                  keymap_opts)
  vim.api.nvim_buf_set_keymap(help_bufnr, "n", "g?", ":lua ToggleHelp(" .. help_bufnr .. ")<CR>", keymap_opts)
end


local function set_waypoint_keybinds()
  set_shared_keybinds(wp_bufnr)

  vim.api.nvim_buf_set_keymap(wp_bufnr, 'n', 'q',     ":lua Leave()<CR>",                         keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, 'n', '<esc>', ":lua Leave()<CR>",                         keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "g?",    ":<C-u>lua ToggleHelp()<CR>",               keymap_opts)

  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", ">",     ":<C-u>lua IndentLine(1)<CR>",              keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "<",     ":<C-u>lua IndentLine(-1)<CR>",             keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "ri",    ":lua ResetCurrentIndent()<CR>",            keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "rI",    ":lua ResetAllIndent()<CR>",                keymap_opts)

  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "zL",    ":<C-u>lua Scroll(1)<CR>",                  keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "zH",    ":<C-u>lua Scroll(-1)<CR>",                 keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "0",     ":lua ResetScroll()<CR>",                   keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "rs",    ":lua ResetScroll()<CR>",                   keymap_opts)

  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "j",     ":lua NextWaypoint()<CR>",                  keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "k",     ":lua PrevWaypoint()<CR>",                  keymap_opts)

  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "K",     ":<C-u>lua MoveWaypointUp()<CR>",           keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "J",     ":<C-u>lua MoveWaypointDown()<CR>",         keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "sg",    ":lua MoveWaypointToTop()<CR>",             keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "sG",    ":lua MoveWaypointToBottom()<CR>",          keymap_opts)
  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "<CR>",  ":lua GoToCurrentWaypoint()<CR>",           keymap_opts)

  vim.api.nvim_buf_set_keymap(wp_bufnr, "n", "dd",    ":<C-u>lua RemoveCurrentWaypoint()<CR>",    keymap_opts)
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
  }

  ---@type table<table<string>>
  local toggles = {}
  ---@type table<table<table<waypoint.HighlightRange>>>
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
  local aligned_toggles = uw.align_waypoint_table(toggles, {"string", "string"}, toggle_highlights, false, nil)
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

  p(lines)
  p(highlights)

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
    callback = Close,
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
  for _=1, vim.v.count1 do
    local indent = state.waypoints[state.wpi].indent + increment
    state.waypoints[state.wpi].indent = u.clamp(
      indent, 0, constants.max_indent
    )
  end
  draw()
end

function MoveWaypointUp()
  if #state.waypoints <= 1 or (state.wpi == 1) then return end
  for _=1, vim.v.count1 do
    local temp = state.waypoints[state.wpi - 1]
    state.waypoints[state.wpi - 1] = state.waypoints[state.wpi]
    state.waypoints[state.wpi] = temp
    state.wpi = state.wpi - 1
  end
  draw("swap")
end

function MoveWaypointDown()
  if #state.waypoints <= 1 or (state.wpi == #state.waypoints) then return end
  for _=1, vim.v.count1 do
    local temp = state.waypoints[state.wpi + 1]
    state.waypoints[state.wpi + 1] = state.waypoints[state.wpi]
    state.waypoints[state.wpi] = temp
    state.wpi = state.wpi + 1
  end
  draw("swap")
end

function MoveWaypointToTop()
  if #state.waypoints <= 2 or state.wpi == 1 then return end
  local temp = state.waypoints[state.wpi]
  for i=state.wpi, 2, -1 do
    state.waypoints[i] = state.waypoints[i-1]
  end
  state.waypoints[1] = temp
  state.wpi = 1
  draw("swap")
end

function MoveWaypointToBottom()
  if #state.waypoints <= 2 or state.wpi == #state.waypoints then return end
  local temp = state.waypoints[state.wpi]
  for i=state.wpi, #state.waypoints - 1 do
    state.waypoints[i] = state.waypoints[i+1]
  end
  state.waypoints[#state.waypoints] = temp
  state.wpi = #state.waypoints
  draw("swap")
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
    draw("move_to_waypoint")
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
    draw("move_to_waypoint")
  end
end

function M.GoToCurrentWaypoint()
  if state.wpi == nil then return end

  if wp_bufnr then Leave() end

  --- @type waypoint.Waypoint | nil 
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

function IncreaseContext(increment)
  for _=1, vim.v.count1 do
    state.context = u.clamp(state.context + increment, 0)
    state.view.lnum = nil
  end

  clamp_view()
  draw("context")
end

function IncreaseBeforeContext(increment)
  for _=1, vim.v.count1 do
    state.before_context = u.clamp(state.before_context + increment, 0)
    state.view.lnum = nil
  end

  clamp_view()
  draw("context")
end

function IncreaseAfterContext(increment)
  for _=1, vim.v.count1 do
    state.after_context = u.clamp(state.after_context + increment, 0)
    state.view.lnum = nil
  end

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
  for _=1, vim.v.count1 do
    local leftcol_max = u.clamp(longest_line_len - win_width, 0)
    state.view.leftcol = u.clamp(state.view.leftcol + increment, 0, leftcol_max)
    state.view.col = u.clamp(state.view.col, state.view.leftcol, state.view.leftcol + win_width - 1)
  end
  draw("scroll")
end

function ResetScroll()
  state.view.col = 0
  state.view.leftcol = 0
  draw("scroll")
end


function ToggleAnnotation()
  state.show_annotation = not state.show_annotation
  if help_bufnr then
    draw_help()
  else
    draw()
  end
end

function TogglePath()
  state.show_path = not state.show_path
  if help_bufnr then
    draw_help()
  else
    draw()
  end
end

function ToggleFullPath()
  state.show_full_path = not state.show_full_path
  if help_bufnr then
    draw_help()
  else
    draw()
  end
end

function ToggleLineNum()
  state.show_line_num = not state.show_line_num
  if help_bufnr then
    draw_help()
  else
    draw()
  end
end

function ToggleFileText()
  state.show_file_text = not state.show_file_text
  if help_bufnr then
    draw_help()
  else
    draw()
  end
end

function ToggleContext()
  state.show_context = not state.show_context
  if help_bufnr then
    draw_help()
  else
    draw()
  end
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
    draw()
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
  vim.api.nvim_buf_set_option(wp_bufnr, 'wrap', false)

  vim.api.nvim_create_autocmd("WinLeave", {
    group = constants.window_augroup,
    buffer = wp_bufnr,
    callback = Close,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = constants.window_augroup,
    buffer = wp_bufnr,
    callback = SetWaypointForCursor,
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
    vim.api.nvim_win_set_option(winnr, 'winhl', 'NormalFloat:Normal')
    vim.api.nvim_win_set_option(bg_winnr, 'winhl', 'NormalFloat:Normal')
  end

  -- I added this because if you open waypoint from telescope, it has wrap disabled
  -- I'm sure there are a bunch of other edge cases like this lurking around
  vim.api.nvim_win_set_option(winnr, "wrap", false)

  -- keymaps
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

  set_waypoint_keybinds()

  state.view.leftcol = 0
  draw("move_to_waypoint")
  highlight.highlight_custom_groups()
end

function Close()
  vim.api.nvim_buf_clear_namespace(wp_bufnr, constants.ns, 0, -1)
  vim.api.nvim_win_close(bg_winnr, true)
  vim.api.nvim_win_close(winnr, true)
  vim.api.nvim_buf_delete(wp_bufnr, {})
  vim.api.nvim_buf_delete(bg_bufnr, {})
  vim.api.nvim_del_augroup_by_name(constants.window_augroup)
  is_open = false
  wp_bufnr = nil
  bg_bufnr = nil
  winnr = nil
  bg_winnr = nil
  help_bufnr = nil
end

function Leave()
  vim.cmd("wincmd w")
end

return M
