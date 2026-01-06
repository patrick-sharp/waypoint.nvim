local M = {}

--- @param bufnr integer
--- @param line integer one-indexed line number to get the synid at
--- @param col integer one-indexed column number to get the synid at
--- @return integer the id of the highlight group at this position in the buffer with number bufnr
local function get_highlight_id_at_pos(bufnr, line, col)
  --- @type integer
  local synid

  vim.api.nvim_buf_call(bufnr, function()
    synid = vim.fn.synID(line, col, 1)
  end)

  --- @type integer
  local hl_id = vim.fn.synIDtrans(synid)
  return hl_id
end

--- @param bufnr      integer
--- @param lines      string[]
--- @param start_line integer zero-indexed
--- @return waypoint.HighlightRange[][] length of returned table is equal to number of lines.
function M.get_vanilla_syntax_highlights(bufnr, lines, start_line)
  local hlranges = {}
  for i,line in pairs(lines) do
    local line_hlranges = {}
    local col_start = 1
    local curr_hl_id = get_highlight_id_at_pos(bufnr, i + start_line, 1)
    for col=2,#line do
      local hl_id = get_highlight_id_at_pos(bufnr, i + start_line, col)
      if hl_id ~= curr_hl_id then
        if curr_hl_id ~= 0 then
          table.insert(line_hlranges, {
            nsid = 0,
            hl_group = curr_hl_id,
            col_start = col_start,
            col_end = col - 1,
          })
        end
        curr_hl_id = hl_id
        col_start = col
      end
    end
    if curr_hl_id ~= 0 then
      table.insert(line_hlranges, {
        nsid = 0,
        hl_group = curr_hl_id,
        col_start = col_start,
        col_end = #line,
      })
    end
    table.insert(hlranges, line_hlranges)
  end

  return hlranges
end

return M
