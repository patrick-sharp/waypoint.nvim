local M = {}
local highlighter = vim.treesitter.highlighter
local constants = require("waypoint.constants")
local u = require("waypoint.utils")

---@class waypoint.TreesitterHighlight
---@field hl_id   integer
---@field hl_name string 
---keep in mind that this range is a raw range from treesitter, so the column
---is 0 indexed. nvim_buf_add_extmark expects 1-indexed, so we adjust it when 
---we actually return highlight ranges. we don't adjust the column because 0 
---indexed exclusive is the same 1 indexed inclusive, except when the col is 0
---@field range { [1]: integer, [2]: integer, [3]: integer, [4]: integer }

---@param start_line integer zero-indexed, inclusive
---@param end_line   integer zero-indexed, exclusive
---@return waypoint.TreesitterHighlight[]
function M.get_nodes_with_highlights(bufnr, start_line, end_line)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  -- zero-indexed, inclusive
  start_line = math.max(0, start_line or 0)
  -- zero-indexed, exclusive
  end_line = math.min(end_line or vim.api.nvim_buf_line_count(bufnr), vim.api.nvim_buf_line_count(bufnr))

  local self = highlighter.active[bufnr]
  if not self then return {} end

  ---@type waypoint.TreesitterHighlight[]
  local results = {}

  local buf_highlighter = vim.treesitter.highlighter.active[bufnr]
  buf_highlighter.tree:for_each_tree(function(tstree, tree)
    local root = tstree:root()
    local q = buf_highlighter:get_query(tree:lang())
    local iter = q:query():iter_captures(root, buf_highlighter.bufnr, start_line, end_line)
    for id, node in iter do
      local capture = q:query().captures[id] -- name of the capture in the query, e.g. "number"
      if capture ~= nil then
        -- 0-indexed, inclusive lower bound, exclusive upper bound
        local start_row, start_col = node:start()
        -- 0-indexed, inclusive lower bound, exclusive upper bound
        local end_row, end_col = node:end_()

        local hl_group = '@' .. capture .. '.' .. tree:lang()

        table.insert(results,
          {
            range = {
              start_row,
              start_col,
              end_row,
              end_col,
            },
            hl_name = hl_group,
            hl_id = vim.api.nvim_get_hl_id_by_name(hl_group)
          })
      end
    end
  end)

  return results
end


---@param bufnr      integer
---@param lines      string[] the lines of text in the file that we're getting the highlights for
---@param start_line integer one-indexed, inclusive
---@param end_line   integer one-indexed, exclusive
---@return waypoint.HighlightRange[][] hlranges array of all syntax highlights on each line.
function M.get_treesitter_syntax_highlights(bufnr, lines, start_line, end_line)
  assert(#lines == end_line - start_line)
  -- convert to zero-indexed
  -- start_line = start_line - 1
  -- end_line = end_line - 1

  ---@type waypoint.TreesitterHighlight[]
  local treesitter_highlights = M.get_nodes_with_highlights(bufnr, start_line - 1, end_line - 1) -- this function takes zero-indexed parameters
  ---@type waypoint.HighlightRange[]
  local hlranges = {}
  for _=1, #lines do
    table.insert(hlranges, {})
  end
  for _,ts_highlight in ipairs(treesitter_highlights) do
    local hl_start_line = ts_highlight.range[1] + 1 -- one-indexed
    local hl_end_line = ts_highlight.range[3] + 1   -- one-indexed
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
      ---@type integer
      local range_start_line
      ---@type integer
      local range_start_col
      ---@type integer
      local range_end_line
      ---@type integer
      local range_end_col

      if ts_highlight.range[1] + 1 < start_line then
        range_start_line = start_line
        range_start_col = 0
      else
        range_start_line = ts_highlight.range[1] + 1
        range_start_col = ts_highlight.range[2]
      end

      if end_line <= ts_highlight.range[3] + 1 then
        range_end_line = end_line - 1
        range_end_col = u.vislen(lines[#lines])
      else
        if ts_highlight.range[4] == 0 then
          range_end_line = ts_highlight.range[3] -- remember end_line is exclusive, and the ts_highlight.range fields are zero-indexed
          local line_i =  ts_highlight.range[3] - ts_highlight.range[1]
          range_end_col = u.vislen(lines[line_i])
        else
          range_end_line = ts_highlight.range[3] + 1 -- remember end_line is exclusive, and the ts_highlight.range fields are zero-indexed
          range_end_col = ts_highlight.range[4]
        end
      end

      for i = range_start_line, range_end_line do
        local line_i = i - start_line + 1
        local col_start
        if line_i == 1 then
          col_start = range_start_col
        else
          col_start = 0
        end
        local col_end
        -- if i == end_i then
        if line_i == #lines then
          -- for some reason, some treesitter highlights have their end column
          -- past the end of the line. This will cause an "end_col out of range"
          -- error when you try to make an extmark make an extmark.
          -- col_end = math.min(range_end_col, u.vislen(lines[i]))
          col_end = math.min(range_end_col, u.vislen(lines[line_i]))
        else
          col_end = u.vislen(lines[line_i])
        end
        table.insert(hlranges[line_i], {
          ns = constants.ns,
          hl_group = ts_highlight.hl_id,
          col_start = col_start,
          col_end = col_end,
        })
      end
    end
  end
  assert(#hlranges == end_line - start_line)
  return hlranges
end

return M

