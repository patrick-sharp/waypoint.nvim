local M = {}

local constants = require("waypoint.constants")
local config = require("waypoint.config")
local highlight_treesitter = require("waypoint.highlight_treesitter")
local highlight_vanilla = require("waypoint.highlight_vanilla")
local u = require("waypoint.utils")
local p = require ("waypoint.print")

--- @param waypoint waypoint.Waypoint
--- @return { [1]: integer, [2]: integer } | nil
function M.extmark_for_waypoint(waypoint)
  if waypoint.extmark_id then
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    --- @type { [1]: integer, [2]: integer }
    local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
    return extmark
  end
  return nil
end

--- @class waypoint.WaypointFileText
--- @field extmark              { [1]: integer, [2]: integer } the zero-indexed row,col coordinates of the extmark corresponding to this waypoint
--- @field lines                string[] the lines of text from the file the waypoint is in. Includes the line the waypoint is on and the lines in the context around the waypoint.
--- @field waypoint_linenr      integer the zero-indexed line number the waypoint is on within the file.
--- @field context_start_linenr integer the zero-indexed line number within the file of the first line of the context
--- @field highlight_ranges     waypoint.HighlightRange[][] the syntax highlights for each line in lines. This table will have the same number of elements as lines.
--- @field file_start_idx       integer index within lines where the start of the file is, or 1 if the file starts before the context
--- @field file_end_idx         integer index within lines where the end of the file is, or #lines + 1 if the file ends after the context

--- @param waypoint waypoint.Waypoint
--- @param num_lines_before integer
--- @param num_lines_after integer
--- @return waypoint.WaypointFileText
function M.get_waypoint_context(waypoint, num_lines_before, num_lines_after)
  local bufnr = vim.fn.bufnr(waypoint.filepath)

  if waypoint.extmark_id == -1 then
    --- @type table<string>
    local lines = {}
    --- @type table<table<waypoint.HighlightRange>>
    local hlranges = {}
    for _=1, num_lines_before do
      table.insert(lines, "")
      table.insert(hlranges, {})
    end
    if waypoint.error then
      table.insert(lines, "Error: " .. waypoint.error)
    elseif waypoint.bufnr == -1 then
      table.insert(lines, "Error: file does not exist")
    else
      table.insert(lines, "Error: line number is out of bounds")
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
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})

  -- zero-indexed line number
  local extmark_line_nr = extmark[1]

  -- zero-indexed line number, inclusive bound
  local start_line_nr = u.clamp(extmark[1] - num_lines_before, 0)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  -- zero-indexed line number, exclusive bound
  local end_line_nr = u.clamp(extmark[1] + 1 + num_lines_after, 0, line_count)

  local marked_line_idx = extmark_line_nr - start_line_nr -- zero-indexed
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line_nr, end_line_nr, false)

  -- figure out how each line is highlighted
  --- @type table<table<waypoint.HighlightRange>>
  local hlranges = {}
  local no_active_highlights = false

  if constants.highlights_on then
    local file_uses_treesitter = vim.treesitter.highlighter.active[bufnr]
    if not config.enable_highlight then
      no_active_highlights = true
    elseif file_uses_treesitter then
      hlranges = highlight_treesitter.get_treesitter_syntax_highlights(bufnr, lines, start_line_nr, end_line_nr)
    elseif pcall(vim.api.nvim_buf_get_var, bufnr, "current_syntax") then
      hlranges = highlight_vanilla.get_vanilla_syntax_highlights(bufnr, lines, start_line_nr)
    else
      no_active_highlights = true
    end
  else
    no_active_highlights = true
  end

  assert(#lines == #hlranges or no_active_highlights, "#lines == " .. #lines ..", #hlranges == " .. #hlranges .. ", but they should be the same" )

  -- if the waypoint context extends to before the start of the file or after
  -- the end, pad to the length of the context with empty lines
  local lines_before_start = start_line_nr - (extmark[1] - num_lines_before)
  local lines_after_end = (extmark[1] + 1 + num_lines_after) - end_line_nr

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
--- @field indents table<integer> | nil if this is non-nil, add indent[i] levels of indentation waypoint[i]
--- @field width_override table<integer | nil> | nil if this is non-nil, override column i's width with width_override[i] if non-nil

--- @param t table<table<string>> rows x columns x content
--- @param table_cell_types table<string> type of each column
--- @param highlights table<table<string | table<waypoint.HighlightRange>>>   rows x columns x (optionally) multiple highlights for a given column. This parameter is mutated to adjust the highlights of each line so they will work after the alignment.
--- @param opts waypoint.AlignTableOpts | nil
--- @return table<string>
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
    local width = u.get_in(opts, {"width_override", i}) or max_width
    assert(max_width <= width, "Max width of column " .. widest_column .. "(" .. tostring(max_width) ..  ") is greater than column width of " .. tostring(width))
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
          table.insert(row_highlights[j], {
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



return M
