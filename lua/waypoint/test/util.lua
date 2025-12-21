local M = {}

local constants = require("waypoint.constants")
local floating_window = require("waypoint.floating_window")
local u = require("waypoint.utils")

---@return string[][]
function M.get_waypoint_buffer_lines()
  local pattern = ' ' .. constants.table_separator .. ' '
  local bufnr = floating_window.get_bufnr()
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_count, true)

  ---@type string[]
  local result = {}

  for i = 1, line_count do
    local split = u.split(lines[i], pattern)
    for k,v in ipairs(split) do
      split[k] = u.trim(v)
    end
    table.insert(result, split)
  end
  return result
end

return M
