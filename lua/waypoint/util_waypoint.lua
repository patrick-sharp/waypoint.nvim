local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local draw_cache = require("waypoint.draw_cache")
local highlight_treesitter = require("waypoint.highlight_treesitter")
local highlight_vanilla = require("waypoint.highlight_vanilla")
local message = require("waypoint.message")
local state = require("waypoint.state")
local u = require("waypoint.util")

---@param waypoint waypoint.Waypoint
---@return integer, boolean
function M.bufnr_from_waypoint(waypoint)
  local bufnr = waypoint.bufnr or vim.fn.bufnr(waypoint.filepath)
  return bufnr, u.is_buffer_valid(bufnr)
end

---@param bufnr integer
---@param extmark_id integer?
---@return integer?
function M.linenr_from_extmark_id(bufnr, extmark_id)
  local extmark = M.buf_get_extmark(bufnr, extmark_id)
  if not extmark then return nil end
  return extmark[1]
end

---@param waypoint waypoint.Waypoint
---@return waypoint.Extmark?
function M.extmark_from_waypoint(waypoint)
  local bufnr, ok = M.bufnr_from_waypoint(waypoint)
  if not ok or waypoint.extmark_id == -1 or waypoint.extmark_id == nil then
    return nil
  end

  return M.buf_get_extmark(bufnr, waypoint.extmark_id)
end

---@param waypoint waypoint.Waypoint
---@return string
function M.filepath_from_waypoint(waypoint)
  if not waypoint.has_buffer and waypoint.filepath then
    return waypoint.filepath
  end
  assert(u.is_buffer_valid(waypoint.bufnr), "bufnr of " .. tostring(waypoint.bufnr) .. " is invalid")
  return u.path_from_buf(waypoint.bufnr)
end

-- note that for speed, the path can be in a few different formats
---@param waypoint waypoint.Waypoint
---@param use_basename boolean
---@return string
function M.drawn_filepath_from_waypoint(waypoint, use_basename)
  if not waypoint.has_buffer and waypoint.filepath then
    if use_basename then
      return vim.fn.fnamemodify(waypoint.filepath, ":t")
    else
      return waypoint.filepath
    end
  end
  local path = vim.api.nvim_buf_get_name(waypoint.bufnr)
  if use_basename then
    path = vim.fn.fnamemodify(path, ":t")
  else
    path = vim.fn.fnamemodify(path, ":.")
  end
  return path
end

---@param waypoint waypoint.Waypoint
---@return integer? the one-indexed line number a waypoint's extmark is on, or nil if it doesn't have one
function M.linenr_from_waypoint(waypoint)
  local extmark = M.extmark_from_waypoint(waypoint)
  if not extmark then return waypoint.linenr end
  return extmark[1]
end

---@param waypoint waypoint.Waypoint
---@return boolean
function M.should_draw_waypoint(waypoint)
  if not waypoint.has_buffer then
    return true
  end
  local extmark = M.extmark_from_waypoint(waypoint)
  if not extmark or not extmark[3] or extmark[3].invalid then
    return false
  end
  return true
end

-- sets the extmark for a waypoint. moves the extmark if it already exists, creates a new one otherwise
---@param waypoint waypoint.Waypoint
---@param linenr integer?
function M.wp_set_extmark(waypoint, linenr)
  local bufnr, ok = M.bufnr_from_waypoint(waypoint)

  local extmark_linenr = waypoint.linenr or linenr

  assert(ok)
  assert(extmark_linenr)

  local opts = {}
  if waypoint.extmark_id then
    local extmark = M.buf_get_extmark(bufnr, waypoint.extmark_id)
    if extmark then
      opts.extmark_id = waypoint.extmark_id
    end
  end

  waypoint.extmark_id = M.buf_set_extmark(bufnr, extmark_linenr, opts)
  return true
end

---@class waypoint.WaypointContext
---@field extmark              waypoint.Extmark
---@field lines                string[] the lines of text from the file the waypoint is in. Includes the line the waypoint is on and the lines in the context around the waypoint.
---@field unpadded_lines       string[] the lines of text before empty lines are added to the front and back to pad for missing lines before/after the file
---@field waypoint_linenr      integer the zero-indexed line number the waypoint is on within the file.
---@field context_start_linenr integer the zero-indexed line number within the file of the first line of the context
---@field context_end_linenr   integer the zero-indexed line number within the file of the last line of the context (meaning it's an inclusive bound)
-----@field highlight_ranges     waypoint.HighlightRange[][] the syntax highlights for each line in lines. This table will have the same number of elements as lines.
---@field file_start_idx       integer index within lines where the start of the file is, or 1 if the file starts before the context
---@field file_end_idx         integer index within lines where the end of the file is, or #lines + 1 if the file ends after the context

---@param waypoint waypoint.Waypoint
---@param num_lines_before integer
---@param num_lines_after integer
---@param is_in_view boolean? whether the waypoint is visible in the current view of the waypoint window (false/nil if offscreen)
---@return waypoint.WaypointContext
function M.get_waypoint_context(waypoint, num_lines_before, num_lines_after, is_in_view)
  local bufnr, ok = M.bufnr_from_waypoint(waypoint)
  local maybe_extmark = M.extmark_from_waypoint(waypoint)

  if not maybe_extmark then
    ---@type string[]
    local lines = {}
    ---@type waypoint.HighlightRange[][]
    local hlranges = {}

    for _=1, num_lines_before do
      table.insert(lines, "")
      table.insert(hlranges, {})
    end

    if waypoint.error then
      table.insert(lines, waypoint.error)
    elseif not waypoint.has_buffer then
      table.insert(lines, message.no_open_buffer_for_file)
    else
      if not ok then
        table.insert(lines, message.missing_file_err_msg)
      else
        table.insert(lines, constants.error_line_oob)
      end
    end
    table.insert(hlranges, {{
      nsid = constants.ns,
      hl_group = "WarningMsg",
      col_start = 1,
      col_end = #lines[#lines],
    }})

    for _=1, num_lines_after do
      table.insert(lines, "")
      table.insert(hlranges, {})
    end

    return {
      extmark = nil,
      lines = lines,
      unpadded_lines = lines,
      waypoint_linenr = num_lines_before,
      context_start_linenr = waypoint.linenr,
      context_end_linenr = waypoint.linenr,
      file_start_idx = num_lines_before + 1,
      file_end_idx = num_lines_before + 2,
      -- highlight_ranges = hlranges,
    }
  end

  ---@type waypoint.Extmark
  local extmark = maybe_extmark

  -- one-indexed line number
  local extmark_line_nr = extmark[1]

  -- one-indexed line number, inclusive bound
  local start_linenr = u.clamp(extmark_line_nr - num_lines_before, 1)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  -- one-indexed line number, exclusive bound
  local end_linenr = u.clamp(extmark_line_nr + num_lines_after + 1, 1, line_count + 1)

  local marked_line_idx = extmark_line_nr - start_linenr -- zero-indexed
  -- this function takes zero indexed-parameters, inclusive lower bound, exclusive upper bound
  ---@type string[]
  local lines
  if waypoint.annotation then
    lines = {}
    for _=start_linenr, extmark_line_nr-1 do
      table.insert(lines, "")
    end
    table.insert(lines, waypoint.annotation)
    for _=extmark_line_nr+1,end_linenr-1 do
      table.insert(lines, "")
    end
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, start_linenr - 1, end_linenr - 1, false)
  end

  -- -- figure out how each line is highlighted
  -- ---@type waypoint.HighlightRange[][]
  -- local hlranges = {}
  --
  -- local has_highlights = is_in_view and u.any({
  --   constants.highlights_on,
  --   config.enable_highlight,
  --   waypoint.annotation,
  -- })
  --
  -- if has_highlights then
  --   local file_uses_treesitter = vim.treesitter.highlighter.active[bufnr]
  --   if file_uses_treesitter then
  --     hlranges = highlight_treesitter.get_treesitter_syntax_highlights(bufnr, lines, start_linenr, end_linenr)
  --   elseif pcall(vim.api.nvim_buf_get_var, bufnr, "current_syntax") then
  --     hlranges = highlight_vanilla.get_vanilla_syntax_highlights(bufnr, lines, start_linenr, end_linenr)
  --   else
  --     for i=1,#lines do hlranges[i] = {} end
  --   end
  -- else
  --   for i=1,#lines do hlranges[i] = {} end
  -- end
  --
  -- assert(#lines == #hlranges, "#lines == " .. #lines ..", #hlranges == " .. #hlranges .. ", but they should be the same" )

  -- if the waypoint context extends to before the start of the file or after
  -- the end, pad to the length of the context with empty lines
  local lines_before_start = start_linenr - (extmark_line_nr - num_lines_before)
  local lines_after_end = (extmark_line_nr + 1 + num_lines_after) - end_linenr

  local padded_lines = {}
  -- local padded_hlranges = {}

  for _=1, lines_before_start do
    table.insert(padded_lines, "")
    -- table.insert(padded_hlranges, {})
  end

  for i=1,#lines do
    table.insert(padded_lines, lines[i])
    -- table.insert(padded_hlranges, hlranges[i])
  end

  for _=1, lines_after_end do
    table.insert(padded_lines, "")
    -- table.insert(padded_hlranges, {})
  end

  -- assert(#padded_lines == #padded_hlranges)

  return {
    extmark = extmark,
    lines = padded_lines,
    unpadded_lines = lines,
    waypoint_linenr = marked_line_idx + lines_before_start,
    context_start_linenr = start_linenr,
    context_end_linenr = end_linenr,
    file_start_idx = lines_before_start + 1,
    file_end_idx = #padded_lines - lines_after_end + 1,
    -- highlight_ranges = padded_hlranges,
  }
end

---@param waypoint waypoint.Waypoint
---@param context waypoint.WaypointContext
---@param num_lines_before integer
---@param num_lines_after integer
---@param is_in_view boolean
---@param use_cache boolean
---@param idx integer index of waypoint within the table of drawn waypoints.
---@return waypoint.HighlightRange[][]
function M.get_waypoint_highlights(waypoint, context, num_lines_before, num_lines_after, is_in_view, idx, use_cache)
  ---@type waypoint.HighlightRange[][]
  local result

  local did_use_cache = false

  local bufnr, ok = M.bufnr_from_waypoint(waypoint)
  local has_highlights = is_in_view and u.any({
    constants.highlights_on,
    config.enable_highlight,
    waypoint.annotation,
  })
  if not context.extmark then
    result = {{}}
  elseif not has_highlights then
    result = {}
    for i=1,#context.lines do result[i] = {} end
  elseif use_cache and draw_cache.highlight_cache[idx] then
    -- have to deepcopy because the highlights will get aligned later.
    -- It would save a little time to cache highlight alignment too, but then I
    -- would have to invalidate the cache if the widths of columns change.
    -- Getting highlights is the more expensive operation because we have to
    -- traverse the treesitter tree, so I prefer to cache that.
    result = vim.deepcopy(draw_cache.highlight_cache[idx])
    did_use_cache = true
  else
    assert(ok)

    local lines = context.unpadded_lines
    local file_uses_treesitter = vim.treesitter.highlighter.active[bufnr]
    local start_linenr = context.context_start_linenr
    local end_linenr = context.context_end_linenr
    local hlranges

    ---@type waypoint.HighlightRange[][]
    if file_uses_treesitter then
      hlranges = highlight_treesitter.get_treesitter_syntax_highlights(bufnr, lines, start_linenr, end_linenr)
    elseif pcall(vim.api.nvim_buf_get_var, bufnr, "current_syntax") then
      hlranges = highlight_vanilla.get_vanilla_syntax_highlights(bufnr, lines, start_linenr, end_linenr)
    else
      hlranges = {}
      for i=1,#context.unpadded_lines do hlranges[i] = {} end
    end

    local extmark_line_nr = context.extmark[1]

    -- if the waypoint context extends to before the start of the file or after
    -- the end, pad to the length of the context with empty lines
    local lines_before_start = start_linenr - (extmark_line_nr - num_lines_before)
    local lines_after_end = (extmark_line_nr + 1 + num_lines_after) - end_linenr

    local padded_hlranges = {}

    for _=1, lines_before_start do
      table.insert(padded_hlranges, {})
    end

    for i=1,#lines do
      table.insert(padded_hlranges, hlranges[i])
    end

    for _=1, lines_after_end do
      table.insert(padded_hlranges, {})
    end

    result = padded_hlranges
  end

  if #context.lines ~= #result then
    error("#context.lines is " .. #context.lines .. ", #result is " .. #result)
  end

  if has_highlights and not did_use_cache then
    draw_cache.highlight_cache = draw_cache.highlight_cache or {}
    draw_cache.highlight_cache[idx] = vim.deepcopy(result)
  end
  return result
end

---@class waypoint.AlignTableOpts
---@field column_separator string? if present, add as a separator between each column
---@field win_width integer? if this is non-nil, add spaces to the right of each row to pad to this width
---@field indents integer[]? if this is non-nil, add indent[i] levels of indentation waypoint[i]
---@field width_override (integer?)[]? if this is non-nil, override column i's width with width_override[i] if non-nil
---@field top_view_threshold integer? 
---@field bottom_view_threshold integer? 
---@field use_line_cache boolean?

local concat = table.concat
local s_rep = string.rep
local win_separator = vim.fn.hlID('WinSeparator')

-- if you include top_view_threshold and bottom_view_threshold in opts, only align what's in view
---@param t string[][] rows x columns x content
---@param table_cell_types string[] type of each column
---@param highlights (string | waypoint.HighlightRange[])[][] rows x columns x (optionally) multiple highlights for a given column. This parameter is mutated to adjust the highlights of each line so they will work after the alignment.
---@param opts waypoint.AlignTableOpts?
---@return string[], integer[] each string row in the aligned table and the widths of each column
function M.align_waypoint_table(t, table_cell_types, highlights, opts)
  local nrows = #t
  if nrows == 0 then return {}, {} end
  local ncols = #table_cell_types

  -- cache for vislen and hlIDs to avoid redundant calculations/bridge calls
  local vislens = {} -- 2D map: vislens[row][col]
  local hl_id_cache = {}

  u.span_start("3.get_widths")
  ---@type integer[]
  local widths = {}
  local width_override = opts and opts.width_override
  if width_override then
    widths = width_override
  else
    -- calculate widths
    for c = 1, ncols do
      local max_width = 0

      for r = 1, nrows do
        local row = t[r]
        if row ~= "" then
          vislens[r] = vislens[r] or {}
          local field = row[c]
          local v_len = u.vislen(field)
          vislens[r][c] = v_len
          if v_len > max_width then max_width = v_len end
        end
      end

      widths[c] = max_width
    end
  end
  u.span_end("3.get_widths")

  u.span_start("3.rest")
  -- adjust highlights
  local col_sep = opts and opts.column_separator
  local col_sep_len = col_sep and #col_sep or 0

  for r = 1, nrows do
    local is_in_view = true
    if opts and opts.top_view_threshold and opts.bottom_view_threshold then
      is_in_view = opts.top_view_threshold <= r and r <= opts.bottom_view_threshold
    end
    local row_highlights = highlights[r]
    local row_data = t[r]
    if is_in_view and row_data ~= "" then
      assert(ncols == #row_highlights)
      local offset = 0
      for c = 1, ncols do
        local field = row_data[c]
        vislens[r] = vislens[r] or {}
        local v_len = vislens[r][c]
        if not v_len then
          v_len = u.vislen(field)
          vislens[r][c] = v_len
        end

        assert(v_len)
        local padded_byte_length = widths[c] - v_len + #field
        local col_highlights = row_highlights[c]

        if type(col_highlights) == "string" then
          -- Cache the Highlight ID lookup
          local hl_group = col_highlights
          if not hl_id_cache[hl_group] then
            hl_id_cache[hl_group] = vim.fn.hlID(hl_group)
          end

          row_highlights[c] = {{
            nsid = constants.ns,
            hl_group = hl_id_cache[hl_group],
            col_start = offset,
            col_end = offset + padded_byte_length
          }}
        else
          for k = 1, #col_highlights do
            local hlrange = col_highlights[k]
            hlrange.col_start = hlrange.col_start + offset - 1
            hlrange.col_end = hlrange.col_end + offset
          end
        end

        if col_sep then
          if c < ncols then
            local sep_start = offset + padded_byte_length + 1
            local row_highlights_j = row_highlights[c]
            assert(type(row_highlights_j) ~= "string")
            row_highlights_j[#row_highlights_j+1] = {
              nsid = constants.ns,
              hl_group = win_separator,
              col_start = sep_start,
              col_end = sep_start + col_sep_len
            }
            offset = offset + padded_byte_length + col_sep_len + 2
          end
        else
          offset = offset + padded_byte_length + 1
        end
      end
    end
  end
  u.span_end("3.rest")

  u.span_start("3.concat")
  -- final string assembly
  local result = {}
  local win_width = opts and opts.win_width
  local indents = opts and opts.indents

  for i = 1, nrows do
    if t[i] == "" then
      result[#result+1] = ""
    else
      local is_in_view = true
      if opts and opts.top_view_threshold and opts.bottom_view_threshold then
        is_in_view = opts.top_view_threshold <= i and i <= opts.bottom_view_threshold
      end
      ---@type string
      local line
      if is_in_view then
        local fields = {}
        for j = 1, ncols do
          local field = t[i][j]
          -- local padding = widths[j] - vislens[i][j]
          local padding = widths[j] - (vislens[i] and vislens[i][j] or 0)

          if table_cell_types[j] == "number" then
            fields[j] = s_rep(" ", padding) .. field
          else
            fields[j] = field .. s_rep(" ", padding)
          end
        end

        line = concat(fields, col_sep and (" " .. col_sep .. " ") or " ")

        if win_width then
          local row_len = u.vislen(line) + (indents and indents[i] or 0)
          if row_len < win_width then
            line = line .. s_rep(" ", win_width - row_len)
          end
        end
      else
        if opts and opts.use_line_cache and draw_cache.prev_waypoint_window_lines then
          line = draw_cache.prev_waypoint_window_lines[i]
        else
          line = concat(t[i])
        end
      end
      result[#result+1] = line
    end
  end
  u.span_end("3.concat")

  return result, widths
end


-- if you include top_view_threshold and bottom_view_threshold, will only align highlights for lines currently in view
---@param t string[][] rows x columns x content
---@param table_cell_types string[] type of each column
---@param highlights (string | waypoint.HighlightRange[])[][] rows x columns x (optionally) multiple highlights for a given column. This parameter is mutated to adjust the highlights of each line so they will work after the alignment.
---@param opts waypoint.AlignTableOpts?
function M.align_waypoint_highlights(t, table_cell_types, highlights, opts)
  local nrows = #t
  if nrows == 0 then return {}, {} end
  local ncols = #table_cell_types

  -- cache for vislen and hlIDs to avoid redundant calculations/bridge calls
  local vislens = {} -- 2D map: vislens[row][col]
  local hl_id_cache = {}

  local widths = opts and opts.width_override
  assert(widths, "This function is not intended to be called without width override")

  ---@cast widths integer[]

  -- adjust highlights
  local col_sep = opts and opts.column_separator
  local col_sep_len = col_sep and #col_sep or 0

  -- local num_in_view = 0

  for r = 1, nrows do
    local is_in_view = true
    if opts and opts.top_view_threshold and opts.bottom_view_threshold then
      is_in_view = opts.top_view_threshold <= r and r <= opts.bottom_view_threshold
    end
    local row_highlights = highlights[r]
    local row = t[r]
    if is_in_view and row ~= "" then
    -- if row ~= "" then
      -- num_in_view = num_in_view + 1
      u.span_start("3.in_view")
      assert(ncols == #row_highlights)
      local offset = 0
      for c = 1, ncols do
        local field = row[c]
        vislens[r] = vislens[r] or {}
        local v_len = vislens[r][c]
        if not v_len then
          v_len = u.vislen(field)
          vislens[r][c] = v_len
        end

        local padded_byte_length = widths[c] - v_len + #field
        local col_highlights = row_highlights[c]

        if type(col_highlights) == "string" then
          -- Cache the Highlight ID lookup
          local hl_group = col_highlights
          if not hl_id_cache[hl_group] then
            hl_id_cache[hl_group] = vim.fn.hlID(hl_group)
          end

          row_highlights[c] = {{
            nsid = constants.ns,
            hl_group = hl_id_cache[hl_group],
            col_start = offset,
            col_end = offset + padded_byte_length
          }}
        else
          for k = 1, #col_highlights do
            local hlrange = col_highlights[k]
            hlrange.col_start = hlrange.col_start + offset - 1
            hlrange.col_end = hlrange.col_end + offset
          end
        end

        if col_sep then
          if c < ncols then
            local sep_start = offset + padded_byte_length + 1
            local row_highlights_j = row_highlights[c]
            assert(type(row_highlights_j) ~= "string")
            row_highlights_j[#row_highlights_j+1] = {
              nsid = constants.ns,
              hl_group = win_separator,
              col_start = sep_start,
              col_end = sep_start + col_sep_len
            }
            offset = offset + padded_byte_length + col_sep_len + 2
          end
        else
          offset = offset + padded_byte_length + 1
        end
      end
      u.span_end("3.in_view")
    end
  end
  -- u.log("IN_VIEW", num_in_view)
end

---@param a waypoint.Waypoint
---@param b waypoint.Waypoint
local function waypoint_compare(a, b)
  if a.error and b.error then
    return a.error < b.error
  elseif a.error then
    return true
  elseif b.error then
    return false
  end
  local a_filepath = a.has_buffer and u.path_from_buf(a.bufnr) or a.filepath
  local a_linenr = a.has_buffer and M.linenr_from_waypoint(a) or a.linenr or -1
  local b_filepath = b.has_buffer and u.path_from_buf(b.bufnr) or b.filepath
  local b_linenr = b.has_buffer and M.linenr_from_waypoint(b) or b.linenr or -1

  if a_filepath == b_filepath then
    return a_linenr < b_linenr
  end
  return a_filepath < b_filepath
end

function M.make_sorted_waypoints()
  state.sorted_waypoints = {}
  for _, waypoint in ipairs(state.waypoints) do
    table.insert(state.sorted_waypoints, waypoint)
  end
  table.sort(state.sorted_waypoints, waypoint_compare)
end

---@class waypoint.Extmark
---@field [1] integer row -- one-indexed, unlike base extmark value
---@field [2] integer col
---@field [3] vim.api.keyset.extmark_details

---@param bufnr integer
---@param extmark_id integer?
---@return waypoint.Extmark?
function M.buf_get_extmark(bufnr, extmark_id)
  if extmark_id == nil then return nil end
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, extmark_id, {details=true})
  local details = extmark[3]
  assert(details)
  if #extmark == 0 then
    return nil
  end
  local result = {
    extmark[1] + 1,
    extmark[2],
    details
  }
  return result
end

-- does not set extmark visibility if none exists
---@param wp waypoint.Waypoint
---@param is_visible boolean
---@return boolean whether an extmark exists for this waypoint
function M.set_wp_extmark_visible(wp, is_visible)
  local bufnr = wp.bufnr
  local extmark_id = wp.extmark_id
  if bufnr and extmark_id then
    local extmark = M.buf_get_extmark(bufnr, extmark_id)
    if not extmark or extmark[3].invalid then
      return false
    end
    M.buf_set_extmark(bufnr, extmark[1], {
      is_visible = is_visible,
      extmark_id = extmark_id,
    })
    return true
  end
  return false
end

function M.buf_get_extmarks(bufnr)
  return vim.api.nvim_buf_get_extmarks(bufnr, constants.ns, 0, -1, {details=true})
end

-- does not set extmark visibility if none exists
---@param bufnr integer
function M.buf_hide_extmarks(bufnr)
  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, constants.ns, 0, -1, {details=true})
  -- set all extmarks to be hidden, and only the show the ones whose waypoints exist in current state
  for _,extmark in ipairs(extmarks) do
    local extmark_id = extmark[1]
    local linenr = extmark[2] + 1
    if not extmark[4].invalid then
      M.buf_set_extmark(bufnr, linenr, {
          is_visible = false,
          extmark_id = extmark_id,
        }
      )
    end
  end
end

---@class waypoint.ExtmarkOpts
---@field extmark_id integer?
---@field is_visible boolean?

---@param bufnr integer
---@param linenr integer one-indexed line number
---@param opts waypoint.ExtmarkOpts?
---@return integer extmark id
function M.buf_set_extmark(bufnr, linenr, opts)
  local sign_text = config.mark_char
  local priority = 1 -- waypoints aren't very high priority because you can see them in the waypoint window anyway
  if opts and opts.is_visible == false then
    sign_text = " "
    priority = 0
  end
  return vim.api.nvim_buf_set_extmark(
    bufnr, constants.ns, linenr - 1, -1,
    {
      id = opts and opts.extmark_id,
      sign_text = sign_text,
      priority = priority,
      sign_hl_group = constants.hl_sign,
      invalidate = true,
    }
  )
end

-- since we don't draw waypoints whose text has been deleted
-- return the top selection drawn wpi (or the cursor wpi if not in vis mode),
-- the bottom selection drawn wpi, the first drawable wpi, and the last
-- drawable wpi
---@return integer?, integer?, integer?, integer?
function M.get_drawn_wpi()
  assert(state.wpi)
  assert(u.is_in_visual_mode() == (nil ~= state.vis_wpi))

  ---@type integer?
  local result_wpi_top = nil
  ---@type integer
  local result_wpi_bottom = nil

  ---@type waypoint.Waypoint[]
  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end

  ---@type integer?
  local result_top = nil
  ---@type integer?
  local result_bottom = nil
  for i = 1, #waypoints do
    if M.should_draw_waypoint(waypoints[i]) then
      result_top = i
      break
    end
  end

  if result_top then
    for i = #waypoints, 1, -1 do
      if M.should_draw_waypoint(waypoints[i]) then
        result_bottom = i
        break
      end
    end
  end

  -- find the top and bottom of the whole waypoint array

  if u.is_in_visual_mode() then
    -- keep in mind that the top bound has the lower index
    local top = math.min(state.wpi, state.vis_wpi)
    local bottom = math.max(state.wpi, state.vis_wpi)

    -- check to see if everything is the visual selection is undrawable
    local should_draw_any_in_selection = false

    ---@type integer?
    local top_drawable = nil
    for i = top, bottom do
      if M.should_draw_waypoint(waypoints[i]) then
        should_draw_any_in_selection = true
        top_drawable = i
        break
      end
    end

    if not should_draw_any_in_selection then
      for i = bottom, #waypoints do
        if M.should_draw_waypoint(waypoints[i]) then
          result_wpi_top = i
          result_wpi_bottom = i
          break
        end
      end
    else
      -- if the bottom of the visual selection has since been deleted, don't move it
      local bottom_drawable = bottom
      while not M.should_draw_waypoint(state.waypoints[bottom_drawable]) do
        bottom_drawable = bottom_drawable - 1
      end

      assert(top_drawable)
      assert(bottom_drawable)
      result_wpi_top = top_drawable
      result_wpi_bottom = bottom_drawable
    end
  else
    for i = state.wpi, #waypoints do
      local wp = waypoints[i]
      if M.should_draw_waypoint(wp) then
        result_wpi_top = i
        break
      end
    end
    if not result_wpi_top then
      for i = state.wpi, 1, -1 do
        local wp = waypoints[i]
        if M.should_draw_waypoint(wp) then
          result_wpi_top = i
          break
        end
      end
    end
  end

  return result_wpi_top, result_wpi_bottom, result_top, result_bottom
end

---@class waypoint.Undrawn
---@field i integer
---@field wp waypoint.Waypoint

---@class waypoint.DrawnSplit
---@field cursor_i           integer? one-indexed
---@field cursor_vis_i       integer? one-indexed
---@field top                integer? the index of the topmost part of the visual selection
---@field bottom             integer? the index of the bottommost poart of the visual selection
---@field drawn              waypoint.Waypoint[]
---@field undrawn            waypoint.Undrawn[]
---@field wpi_from_drawn_i   integer[]

-- This exists because:
-- * Waypoints should not be drawn if their extmark has been deleted
-- * No operation should affect undrawn waypoints
-- * Mutations get way easier to do if you don't have to worry about undrawn waypoints
-- (however, bufferless waypoints should always be drawn)
---@return waypoint.DrawnSplit
function M.split_by_drawn()
  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end

  ---@type waypoint.Waypoint[]
  local drawn = {}
  ---@type waypoint.Undrawn[]
  local undrawn = {}
  ---@type integer[]
  local wpi_from_drawn_i = {}
  ---@type integer?
  local cursor_i = nil
  ---@type integer?
  local cursor_vis_i = nil

  for i,wp in ipairs(waypoints) do
    local should_draw = M.should_draw_waypoint(wp)
    if should_draw then
      drawn[#drawn+1] = wp
      wpi_from_drawn_i[#wpi_from_drawn_i+1] = i

      if cursor_i == nil and i >= state.wpi then
        cursor_i = #drawn
      end
      if state.vis_wpi then
        if cursor_vis_i == nil and state.vis_wpi < state.wpi and state.vis_wpi <= i then
          cursor_vis_i = #drawn
        elseif state.wpi < state.vis_wpi and state.wpi < i and i <= state.vis_wpi then
          cursor_vis_i = #drawn
        end
      end
    else
      undrawn[#undrawn+1] = { i = i, wp = wp }
    end
  end
  if state.vis_wpi and not cursor_vis_i then
    cursor_vis_i = cursor_i
  end
  if cursor_i == nil and #drawn > 0 then
    cursor_i = #drawn
  end
  if state.vis_wpi and cursor_vis_i == nil and #drawn > 0 then
    cursor_vis_i = #drawn
  end

  local top = nil
  local bottom = nil
  if cursor_i and cursor_vis_i then
    top = math.min(cursor_i, cursor_vis_i)
    bottom = math.max(cursor_i, cursor_vis_i)
  end

  return {
    drawn = drawn,
    undrawn = undrawn,
    cursor_i = cursor_i,
    cursor_vis_i = cursor_vis_i,
    top = top,
    bottom = bottom,
    wpi_from_drawn_i = wpi_from_drawn_i,
  }
end

  ---@param split waypoint.DrawnSplit
function M.recombine_drawn_split(split)
  local drawn = split.drawn
  local undrawn = split.undrawn

  local waypoints = {}
  local i = 1
  local drawn_i = 1
  local undrawn_i = 1

  while i <= #drawn + #undrawn do
    if undrawn_i <= #undrawn and undrawn[undrawn_i].i == i then
      waypoints[i] = undrawn[undrawn_i].wp
      undrawn_i = undrawn_i + 1
    else
      waypoints[i] = drawn[drawn_i]
      drawn_i = drawn_i + 1
    end
    i = i + 1
  end

  state.wpi = split.wpi_from_drawn_i[split.cursor_i]
  if split.cursor_vis_i then
    state.vis_wpi = split.wpi_from_drawn_i[split.cursor_vis_i]
  end
  state.waypoints = waypoints
end

-- includes the space that appears between waypoints when context > 0
-- returns lines for each waypoint, and the space between waypoints (hardcoded to 1)
---@return integer, integer
function M.lines_per_waypoint()
  local context_lines = state.before_context + 2 * state.context + state.after_context
  if context_lines == 0 then
    return 1, 0
  end
  return context_lines + 1, 1
end

function M.num_lines_before_after()
  local num_lines_before
  local num_lines_after
  if state.show_context then
    num_lines_before = state.before_context + state.context
    num_lines_after = state.after_context + state.context
  else
    num_lines_before = 0
    num_lines_after = 0
  end
  return num_lines_before, num_lines_after
end

return M
