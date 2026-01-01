local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local highlight_treesitter = require("waypoint.highlight_treesitter")
local highlight_vanilla = require("waypoint.highlight_vanilla")
local message = require("waypoint.message")
local state = require("waypoint.state")
local u = require("waypoint.utils")

--- @param waypoint waypoint.Waypoint
--- @return { [1]: integer, [2]: integer } | nil
function M.extmark_for_waypoint(waypoint)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
  if bufnr == -1 or waypoint.extmark_id == -1 then
    return nil
  end
  --- @type table | { [1]: integer, [2]: integer }
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
  if #extmark == 0 then
    return nil
  end
  return extmark
end

--- @class waypoint.WaypointFileText
--- @field extmark              { [1]: integer, [2]: integer } the zero-indexed row,col coordinates of the extmark corresponding to this waypoint
--- @field lines                string[] the lines of text from the file the waypoint is in. Includes the line the waypoint is on and the lines in the context around the waypoint.
--- @field waypoint_linenr      integer the zero-indexed line number the waypoint is on within the file.
--- @field context_start_linenr integer the zero-indexed line number within the file of the first line of the context
--- @field highlight_ranges     waypoint.HighlightRange[][] the syntax highlights for each line in lines. This table will have the same number of elements as lines.
--- @field file_start_idx       integer index within lines where the start of the file is, or 1 if the file starts before the context
--- @field file_end_idx         integer index within lines where the end of the file is, or #lines + 1 if the file ends after the context

---@param waypoint waypoint.Waypoint
function M.set_extmark(waypoint)
  local bufnr = waypoint.bufnr
  vim.api.nvim_buf_set_extmark(bufnr, constants.ns, waypoint.linenr - 1, -1, {
    id = waypoint.extmark_id,
    sign_text = config.mark_char,
    priority = 1,
    sign_hl_group = constants.hl_sign,
  })
end

--- @param waypoint waypoint.Waypoint
--- @param num_lines_before integer
--- @param num_lines_after integer
--- @return waypoint.WaypointFileText
function M.get_waypoint_context(waypoint, num_lines_before, num_lines_after)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
  --local bufnr = waypoint.bufnr

  --- @type nil | { [1]: integer, [2]: integer }
  local maybe_extmark = nil
  if waypoint.extmark_id ~= -1 and bufnr ~= -1 then
    --- @type table | { [1]: integer, [2]: integer }
    local maybe_extmark_ = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
    if #maybe_extmark_ ~= 0 then
      maybe_extmark = maybe_extmark_
    end
  end


  if not maybe_extmark then
    --- @type string[]
    local lines = {}
    --- @type waypoint.HighlightRange[][]
    local hlranges = {}
    for _=1, num_lines_before do
      table.insert(lines, "")
      table.insert(hlranges, {})
    end
    if waypoint.error then
      table.insert(lines, waypoint.error)
    elseif bufnr == -1 or 0 == vim.fn.bufloaded(bufnr) then
      table.insert(lines, message.missing_file_err_msg)
    else
      table.insert(lines, constants.line_oob_error)
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
      waypoint_linenr = num_lines_before,
      context_start_linenr = waypoint.linenr,
      file_start_idx = num_lines_before + 1,
      file_end_idx = num_lines_before + 2,
      highlight_ranges = hlranges,
    }
  end

  --- @type { [1]: integer, [2]: integer }
  local extmark = maybe_extmark

  -- one-indexed line number
  local extmark_line_nr = extmark[1] + 1

  -- one-indexed line number, inclusive bound
  local start_line_nr = u.clamp(extmark_line_nr - num_lines_before, 1)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  -- one-indexed line number, exclusive bound
  local end_line_nr = u.clamp(extmark_line_nr + num_lines_after + 1, 1, line_count + 1)

  local marked_line_idx = extmark_line_nr - start_line_nr -- zero-indexed
  -- this function takes zero indexed-parameters, inclusive lower bound, exclusive upper bound
  ---@type string[]
  local lines
  if waypoint.annotation then
    lines = {}
    for _=start_line_nr, extmark_line_nr-1 do
      table.insert(lines, "")
    end
    table.insert(lines, waypoint.annotation)
    for _=extmark_line_nr+1,end_line_nr-1 do
      table.insert(lines, "")
    end
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, start_line_nr - 1, end_line_nr - 1, false)
  end

  -- figure out how each line is highlighted
  --- @type waypoint.HighlightRange[][]
  local hlranges = {}
  local no_active_highlights = false

  if constants.highlights_on and not waypoint.annotation then
  -- if constants.highlights_on then
    local file_uses_treesitter = vim.treesitter.highlighter.active[bufnr]
    if not config.enable_highlight then
      no_active_highlights = true
    elseif file_uses_treesitter then
      hlranges = highlight_treesitter.get_treesitter_syntax_highlights(bufnr, lines, start_line_nr - 1, end_line_nr - 1)
    elseif pcall(vim.api.nvim_buf_get_var, bufnr, "current_syntax") then
      hlranges = highlight_vanilla.get_vanilla_syntax_highlights(bufnr, lines, start_line_nr - 1)
    else
      no_active_highlights = true
    end
  else
    for i=1,#lines do
      hlranges[i] = {}
    end
    no_active_highlights = true
  end

  assert(#lines == #hlranges or no_active_highlights, "#lines == " .. #lines ..", #hlranges == " .. #hlranges .. ", but they should be the same" )

  -- if the waypoint context extends to before the start of the file or after
  -- the end, pad to the length of the context with empty lines
  local lines_before_start = start_line_nr - (extmark_line_nr - num_lines_before)
  local lines_after_end = (extmark_line_nr + 1 + num_lines_after) - end_line_nr

  local lines_ = {}
  local hlranges_ = {}

  for _=1, lines_before_start do
    table.insert(lines_, "")
    table.insert(hlranges_, {})
  end

  for i=1,#lines do
    table.insert(lines_, lines[i])
    table.insert(hlranges_, hlranges[i])
  end

  for _=1, lines_after_end do
    table.insert(lines_, "")
    table.insert(hlranges_, {})
  end

  return {
    extmark = extmark,
    lines = lines_,
    waypoint_linenr = marked_line_idx + lines_before_start,
    context_start_linenr = start_line_nr,
    file_start_idx = lines_before_start + 1,
    file_end_idx = #lines_ - lines_after_end + 1,
    highlight_ranges = hlranges_,
  }
end


--- @class waypoint.AlignTableOpts
--- @field column_separator string | nil if present, add as a separator between each column
--- @field win_width integer | nil if this is non-nil, add spaces to the right of each row to pad to this width
--- @field indents integer[] | nil if this is non-nil, add indent[i] levels of indentation waypoint[i]
--- @field width_override (integer | nil)[] | nil if this is non-nil, override column i's width with width_override[i] if non-nil

--- @param t string[][] rows x columns x content
--- @param table_cell_types string[] type of each column
--- @param highlights (string | waypoint.HighlightRange[])[][] rows x columns x (optionally) multiple highlights for a given column. This parameter is mutated to adjust the highlights of each line so they will work after the alignment.
--- @param opts waypoint.AlignTableOpts | nil
--- @return string[]
function M.align_waypoint_table(t, table_cell_types, highlights, opts)
  if #t == 0 then
    return {}
  end

  assert(#t[1] == #table_cell_types, "#t[1] == " .. #t[1] ..", #table_cell_types == " .. #table_cell_types .. ", but they should be the same")
  assert(#t == #highlights, "#t == " .. #t ..", #highlights == " .. #highlights .. ", but they should be the same")
  if opts and opts.indents then
    assert(#t == #opts.indents, "#t == " .. #t ..", #indents == " .. #opts.indents .. ", but they should be the same")
  end

  local nrows = #t
  local ncols = #t[1]

  -- figure out how wide each table column is
  local widths = {}
  for i=1,ncols do
    local max_width = 0
    local widest_column = nil
    for j=1,nrows do
      if t[j] ~= "" then
        local field = t[j][i]
        local field_len = u.vislen(field)
        if (field_len > max_width) then
          max_width = field_len
          widest_column = i
        end

      end
    end
    local width_override = u.get_in(opts, {"width_override", i})
    local width = width_override or max_width
    if width_override then
      assert(max_width <= width, "Max width of column " .. tostring(widest_column) .. "(" .. tostring(max_width) ..  ") is greater than width override of " .. tostring(width_override))
    else
      assert(max_width <= width, "Max width of column " .. tostring(widest_column) .. "(" .. tostring(max_width) ..  ") is greater than column width of " .. tostring(width))
    end
    table.insert(widths, width)
  end

  -- now that we know how wide each column is, we can figure out how the 
  -- highlight groups of each line will be adjusted
  for i,row_highlights in pairs(highlights) do
    -- how much to add to col_start and col_end
    -- note that this is a byte offset, not a character offset
    local offset = 0
    assert(#t[i] == #row_highlights, "#t[i] == " .. #t[i] ..", #row_highlights == " .. #row_highlights .. " for row " .. tostring(i) .. ", but they should be the same")
    for j,col_highlights in pairs(row_highlights) do
      local field = t[i][j]
      local padded_byte_length = widths[j] - u.vislen(field) + #field
      if type(col_highlights) == "string" then
        -- accounting for tabs and unicode characters
        row_highlights[j] = {{
          nsid = constants.ns,
          hl_group = col_highlights,
          col_start = offset,
          col_end = offset + padded_byte_length
        }}
      else
        for _,hlrange in pairs(col_highlights) do
          hlrange.col_start = hlrange.col_start + offset - 1
          hlrange.col_end = hlrange.col_end + offset
        end
      end
      if opts and opts.column_separator then
        -- if applicable, highlight the table separator to the right of this column
        if j < #row_highlights then
          local separator_highlight_start = offset + padded_byte_length + 1
          local separator_highlight_end = offset + padded_byte_length + 1 + #opts.column_separator
          local col_highlights_ = row_highlights[j]
          assert(type(col_highlights_) == "table")
          table.insert(col_highlights_, {
            nsid = constants.ns,
            hl_group = 'WinSeparator',
            col_start = separator_highlight_start,
            col_end = separator_highlight_end
          })
        end

        -- the extra 2 for the spaces on either side of the table separator
        offset = offset + padded_byte_length + #opts.column_separator + 2
      else
        -- the extra 1 is the space between columns
        offset = offset + padded_byte_length + 1
      end
    end
  end

  local result = {}
  for i=1,nrows do
    if t[i] == "" then
      table.insert(result, "")
    else
      local fields = {}
      assert(#table_cell_types == #t[i])
      for j=1,ncols do
        local field = t[i][j]
        local padded
        if table_cell_types[j] == "number" then
          padded = string.rep(" ", widths[j] - u.vislen(field)) .. field
        else
          local num_padding_spaces = widths[j] - u.vislen(field)
          padded = field .. string.rep(" ", num_padding_spaces)
        end
        table.insert(fields, padded)
      end
      if opts and opts.column_separator then
        table.insert(result, table.concat(fields, " " .. opts.column_separator .. " "))
      else
        table.insert(result, table.concat(fields, " "))
      end

      if opts and opts.win_width then
        local row_len = u.vislen(result[#result]) + ((opts and opts.indents and opts.indents[i]) or 0)
        if row_len < opts.win_width then
          local num_padding_spaces = opts.win_width - row_len
          result[#result] = result[#result] .. string.rep(" ", num_padding_spaces)
        end
      end
    end
  end
  return result
end

---@param a waypoint.Waypoint
---@param b waypoint.Waypoint
local function waypoint_compare(a, b)
  if a.filepath == b.filepath then
    return a.linenr < b.linenr
  end
  return a.filepath < b.filepath
end

function M.make_sorted_waypoints()
  state.sorted_waypoints = {}
  for _, waypoint in ipairs(state.waypoints) do
    table.insert(state.sorted_waypoints, waypoint)
  end
  table.sort(state.sorted_waypoints, waypoint_compare)
end


return M
