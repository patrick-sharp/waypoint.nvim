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
      split[k] = vim.trim(v)
    end
    table.insert(result, split)
  end
  return result
end

---@return string | nil
function M.get_last_message()
  local messages = vim.split(vim.fn.execute(":messages"), "\n")
  if #messages == nil then
    return
  end
  return messages[#messages]
end

function M.assert_eq(a, b)
  assert(a == b, "\n" .. vim.inspect(a) .. "\n~=\n" .. vim.inspect(b))
end

return M
