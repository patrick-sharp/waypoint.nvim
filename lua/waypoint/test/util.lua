local M = {}

local message = require("waypoint.message")
local ring_buffer = require("waypoint.ring_buffer")
local constants = require("waypoint.constants")
local floating_window = require("waypoint.floating_window")
local u = require("waypoint.utils")

---strings returned by thins function are trimmed to make testing more legible and not depend on screen size
---@return string[][]
function M.get_waypoint_buffer_lines()
  if not floating_window.is_open() then
    error("Cannot get waypoint buffer lines while waypoint window is closed")
  end
  local pattern = ' ' .. constants.table_separator .. ' '
  local bufnr = floating_window.get_bufnr()
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_count, true)

  ---@type string[]
  local result = {}

  for i = 1, line_count do
    local split = u.split(lines[i], pattern)
    for k,v in ipairs(split) do
      split[k] = v
    end
    table.insert(result, split)
  end
  return result
end

---strings returned by thins function are trimmed to make testing more legible and not depend on screen size
---@return string[][]
function M.get_waypoint_buffer_lines_trimmed()
  if not floating_window.is_open() then
    error("Cannot get waypoint buffer lines while waypoint window is closed")
  end
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
  local res, ok = ring_buffer.peek(message.messages)
  if ok then
    return res.msg
  else
    return nil
  end
end

---@return string | nil
function M.nvim_get_last_message()
  local msgs = vim.split(vim.fn.execute(":messages"), "\n")
  if #msgs == nil then
    return
  end
  return msgs[#msgs]
end

---@param expected any
---@param actual any
function M.assert_eq(expected, actual)
  assert(expected == actual, "\n\nShould equal:\nExpected: " .. vim.inspect(expected) .. "\nActual:   " .. vim.inspect(actual) .. "\n")
end

---@param unexpected any
---@param actual any
function M.assert_neq(unexpected, actual)
  assert(unexpected ~= actual, "\n\nShould not equal:\nUnexpected: " .. vim.inspect(unexpected) .. "\nActual:   " .. vim.inspect(actual) .. "\n")
end

-- jump to linenr in current buffer. The extra <C-c> is to reset vim.v.count
---@param linenr integer one-indexed line number
function M.goto_line(linenr)
  vim.cmd.normal({args = {tostring(linenr) .. "G<C-c>"}, bang=true})
end

return M
