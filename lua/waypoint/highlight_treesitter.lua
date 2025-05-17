local M = {}
local highlighter = vim.treesitter.highlighter
local constants = require("waypoint.constants")
local u = require("waypoint.utils")
local p = require("waypoint.print")

--- @class waypoint.TreesitterHighlight
--- @field hl_id   integer
--- @field hl_name string 
--- keep in mind that this range is a raw range from treesitter, so the column
--- is 0 indexed. nvim_buf_add_extmark expects 1-indexed, so we adjust it when 
--- we actually return highlight ranges. we don't adjust the column because 0 
--- indexed exclusive is the same 1 indexed inclusive, except when the col is 0
--- @field range   { [1]: integer, [2]: integer, [3]: integer, [4]: integer }

--- @param start_line integer zero-indexed, inclusive
--- @param end_line   integer zero-indexed, exclusive
--- @return table<waypoint.TreesitterHighlight>
function M.get_nodes_with_highlights(bufnr, start_line, end_line)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  start_line = math.max(0, start_line or 0)
  end_line = math.min(end_line or vim.api.nvim_buf_line_count(bufnr), vim.api.nvim_buf_line_count(bufnr))

  local self = highlighter.active[bufnr]
  if not self then return {} end

  --- @type table<waypoint.TreesitterHighlight>
  local results = {}
  local wp_start_row = start_line
  local wp_end_row = end_line - 1

  local count = 0

  self:for_each_highlight_state(function(state)
    count = count + 1
    local hl_query = state.highlighter_query
    if not hl_query then return end

    local root_node = state.tstree:root()
    local root_start_row, _, root_end_row, _ = root_node:range()

    -- Only consider trees that contain these lines
    if root_start_row > wp_end_row or root_end_row < wp_start_row then return end

    local line = wp_start_row

    state.iter = state.highlighter_query:query():iter_captures(root_node, self.bufnr, line, root_end_row + 1)

    local capture, node
    -- the beginning of the next node's range
    local next_node_range_start = 0
    while next_node_range_start <= wp_end_row do
      capture, node = state.iter(line)
      if node == nil then
        break
      end
      local start_row, start_col, end_row, end_col = node:range()
      if start_row > wp_end_row then
        break
      end

      local hl_id = 0
      local capname = nil
      local hl_name = nil
      if capture then
        -- for some reason, the id returned by this can't be used to get the
        -- highlight group with vim.api.nvim_get_hl. Yet, it works when you add
        -- an extmark with this hl group.
        hl_id = state.highlighter_query:get_hl_from_capture(capture)
        capname = state.highlighter_query._query.captures[capture]
        if not vim.startswith(capname, '_') then
          -- this is the same logic neovim uses to create highlight groups for captures
          hl_name = '@' .. capname .. '.' .. state.highlighter_query.lang
        end
      end

      table.insert(results,
        {
          range = {
            start_row,
            start_col,
            end_row,
            end_col,
          },
          hl_id = hl_id,
          hl_name = hl_name,
        })
    end
  end)
  return results
end


--- @param bufnr      integer
--- @param lines      table<string> the lines of text in the file that we're getting the highlights for
--- @param start_line integer zero-indexed, inclusive
--- @param end_line   integer zero-indexed, exclusive
--- @return table<table<waypoint.HighlightRange>>
function M.get_treesitter_syntax_highlights(bufnr, lines, start_line, end_line)
  --- @type table<waypoint.TreesitterHighlight>
  local treesitter_highlights = M.get_nodes_with_highlights(bufnr, start_line, end_line)
  --- @type table<waypoint.HighlightRange>
  local hlranges = {}
  for _=1, #lines do
    table.insert(hlranges, {})
  end
  for _,ts_highlight in pairs(treesitter_highlights) do
    local hl_start_line = ts_highlight.range[1]
    local hl_end_line = ts_highlight.range[3]
    -- one-indexed index into the highlight ranges table.
    -- e.g. if you're getting highlights where start_line is 20 and end_line is
    -- 23, then line 21 (0-based indexing) will have a hlrange_idx of 2
    local hlrange_idx = math.max(hl_start_line - start_line + 1, 1)
    if hl_start_line == hl_end_line then
      table.insert(hlranges[hlrange_idx], {
        ns = constants.ns,
        hl_group = ts_highlight.hl_id,
        col_start = ts_highlight.range[2] + 1,
        col_end = ts_highlight.range[4],
      })
    else
      -- all are zero indexed. lower bound inclusive, upper bound exclusive
      local range_start_line = math.max(ts_highlight.range[1], start_line) -- make sure we only add highlight ranges for lines in the context, not before
      local range_start_col = ts_highlight.range[2]
      local range_end_line = math.min(ts_highlight.range[3], end_line - 1) -- make sure we only add highlight ranges for lines in the context, not after
      local range_end_col = ts_highlight.range[4]
      if range_end_col == 0 then
        -- since treesitter highlight range upper bound is exclusive, if a
        -- highlight range ends at col 0, treat that ending at the end of the
        -- previous line
        range_end_line = range_end_line - 1
        -- need to use vislen because this is a column length, not a byte length
        range_end_col = u.vislen(lines[range_end_line - start_line + 1])
      end
      -- these are both one-indexed inclusive
      local start_i = range_start_line - start_line + 1
      local end_i = range_end_line - start_line + 1
      p(start_i, end_i, #lines)
      for i = start_i, end_i do
        local col_start
        if i == start_i then
          col_start = range_start_col
        else
          col_start = 0
        end
        local col_end
        if i == end_i then
          -- for some reason, some treesitter highlights have their end column
          -- past the end of the line. This will cause an "end_col out of range"
          -- error when you try to make an extmark make an extmark.
          col_end = math.min(range_end_col, u.vislen(lines[i]))
        else
          col_end = u.vislen(lines[i])
        end
        table.insert(hlranges[i], {
          ns = constants.ns,
          hl_group = ts_highlight.hl_id,
          col_start = col_start,
          col_end = col_end,
        })
      end
    end
  end
  return hlranges
end

return M

