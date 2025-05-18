local M = {}

local constants = require("waypoint.constants")
local config = require("waypoint.config")
local highlight_treesitter = require("waypoint.highlight_treesitter")
local highlight_vanilla = require("waypoint.highlight_vanilla")
local u = require("waypoint.utils")
local p = require ("waypoint.print")

--- @param waypoint waypoint.Waypoint
--- @return { [1]: integer, [2]: integer }
function M.extmark_for_waypoint(waypoint)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
  --- @type { [1]: integer, [2]: integer }
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
  return extmark
end

--- @class waypoint.WaypointFileText
--- @field extmark              { [1]: integer, [2]: integer } the zero-indexed row,col coordinates of the extmark corresponding to this waypoint
--- @field lines                string[] the lines of text from the file the waypoint is in. Includes the line the waypoint is on and the lines in the context around the waypoint.
--- @field waypoint_linenr      integer the zero-indexed line number the waypoint is on within the file.
--- @field context_start_linenr integer the zero-indexed line number within the file of the first line of the context
--- @field highlight_ranges     waypoint.HighlightRange[][] the syntax highlights for each line in lines. This table will have the same number of elements as lines.

--- @param waypoint waypoint.Waypoint
--- @param num_lines_before integer
--- @param num_lines_after integer
--- @return waypoint.WaypointFileText
function M.get_waypoint_context(waypoint, num_lines_before, num_lines_after)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
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

  return {
    extmark = extmark,
    lines = lines,
    waypoint_linenr = marked_line_idx,
    context_start_linenr = start_line_nr,
    highlight_ranges = hlranges,
  }
end


--- @param t table<table<string>>
--- @param table_cell_types table<string>
--- @param highlights table<table<string | table<waypoint.HighlightRange>>>   rows x columns x (optionally) multiple highlights for a given column. This parameter is mutated to adjust the highlights of each line so they will work after the alignment.
--- @param win_width integer
--- @return table<string>
function M.align_waypoint_table(t, table_cell_types, highlights, win_width)
  if #t == 0 then
    return {}
  end
  assert(#t == #highlights, "#t == " .. #t ..", #highlights == " .. #highlights .. ", but they should be the same" )
  local nrows = #t
  local ncols = #t[1]

  -- figure out how wide each table column is
  local widths = {}
  for i=1,ncols do
    local max_width = 0
    for j=1,nrows do
      if t[j] ~= "" then
        local field = t[j][i]
        max_width = math.max(u.vislen(field), max_width)
      end
    end
    table.insert(widths, max_width)
  end

  -- now that we know how wide each table is, we can figure out how the 
  -- highlight groups of each line will be adjusted
  for i,row_highlights in pairs(highlights) do
    -- how much to add to col_start and col_end
    -- note that this is a byte offset, not a character offset
    local offset = 0
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
      -- the extra 2 for the spaces on either side of the table separator
      offset = offset + padded_byte_length + #constants.table_separator + 2
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
      table.insert(result, table.concat(fields, " " .. constants.table_separator .. " "))
      local row_len = u.vislen(result[#result])
      if row_len < win_width then
        local num_padding_spaces = win_width - row_len
        result[#result] = result[#result] .. string.rep(" ", num_padding_spaces)
      end
    end
  end
  return result
end


return M
