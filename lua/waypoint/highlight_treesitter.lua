local M = {}
local highlighter = vim.treesitter.highlighter
local constants = require("waypoint.constants")
local p = require("waypoint.print")

--- @class TreesitterHighlight
--- @field hl_id   integer
--- @field hl_name string 
--- keep in mind that this range is a raw range from treesitter, so the column
--- is 0 indexed. nvim_buf_add_extmark expects 1-indexed, so we adjust it when 
--- we actually return highlight ranges. we don't adjust the column because 0 
--- indexed exclusive is the same 1 indexed inclusive
--- @field range   { [1]: integer, [2]: integer, [3]: integer, [4]: integer }

--- @param start_line   integer   0 indexed, inclusive
--- @param end_line     integer   0 indexed, exclusive
--- @return table<TreesitterHighlight>
function M.get_nodes_with_highlights(bufnr, start_line, end_line)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  start_line = math.max(1, start_line or 1)
  end_line = math.min(end_line or vim.api.nvim_buf_line_count(bufnr), vim.api.nvim_buf_line_count(bufnr))

  local self = highlighter.active[bufnr]
  if not self then return {} end

  --- @type table<TreesitterHighlight>
  local results = {}
  local wp_start_row = start_line
  local wp_end_row = end_line - 1

  self:for_each_highlight_state(function(state)
    local hl_query = state.highlighter_query
    if not hl_query then return end

    local root_node = state.tstree:root()
    local root_start_row, _, root_end_row, _ = root_node:range()

    -- Only consider trees that contain these lines line
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
--- @param start_line integer
--- @param end_line   integer
--- @return table<table<waypoint.HighlightRange>>
function M.get_treesitter_syntax_highlights(bufnr, start_line, end_line)
  --- @type table<TreesitterHighlight>
  local treesitter_highlights = M.get_nodes_with_highlights(bufnr, start_line, end_line)
  local hlranges = {}
  for _=1,(end_line-start_line) do
    table.insert(hlranges, {})
  end
  for _,ts_highlight in pairs(treesitter_highlights) do
    local hl_start_line = ts_highlight.range[1]
    local hl_end_line = ts_highlight.range[3]
    local base_idx = math.max(hl_start_line - start_line + 1, 1)
    p(#hlranges, base_idx, hl_start_line, hl_end_line, start_line, end_line)
    if hl_start_line == hl_end_line then
      table.insert(hlranges[base_idx], {
        ns = constants.ns,
        hl_group = ts_highlight.hl_id,
        col_start = ts_highlight.range[2] + 1,
        col_end = ts_highlight.range[4],
      })
    else
      local start_i
      if hl_start_line >= start_line then
        -- p(base_idx)
        start_i = hl_start_line + 1
        -- table.insert(hlranges[base_idx], {
        --   ns = constants.ns,
        --   hl_group = ts_highlight.hl_id,
        --   col_start = ts_highlight.range[2],
        --   col_end = -1,
        -- })
      else
        start_i = start_line + 1
      end
      local end_i = math.min(hl_end_line, end_line) - 1
      for i=start_i,end_i do
        -- p(base_idx + i - 1)
        -- table.insert(hlranges[base_idx + i - 1], {
        --   ns = constants.ns,
        --   hl_group = ts_highlight.hl_id,
        --   col_start = 0,
        --   col_end = -1,
        -- })
      end
      if hl_end_line <= end_line then
        -- p(hl_end_line - hl_start_line)
        -- table.insert(hlranges[hl_end_line - start_line], {
        --   ns = constants.ns,
        --   hl_group = ts_highlight.hl_id,
        --   col_start = 0,
        --   col_end = ts_highlight.range[4],
        -- })
      end
    end
  end
  return hlranges
end

return M

