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

local waypoint_props = {
  "has_buffer",
  "extmark_id",
  "bufnr",
  "indent",
  "annotation",
  "filepath",
  "text",
  "linenr",
  "error",
}

---@param wp_a waypoint.Waypoint
---@param wp_b waypoint.Waypoint
function M.assert_waypoints_eq(wp_a, wp_b)
  for _,prop in ipairs(waypoint_props) do
    assert(wp_a[prop] == wp_b[prop], "Values for " .. prop .. " do not match: " .. tostring(wp_a[prop]) .. " ~= " .. tostring(wp_b[prop]))
  end
end

-- all parameters are one-indexed
---@param cursor_line integer
---@param cursor_char_col integer
---@param vis_line integer
---@param vis_char_col integer
function M.assert_vis_char_pos(cursor_line, cursor_char_col, vis_line, vis_char_col)
  local cursor = vim.fn.getcharpos('.')
  local vis = vim.fn.getcharpos('v')
  assert(cursor[2] == cursor_line,     "cursor line should be " ..     cursor_line ..     ", but was " .. cursor[2])
  assert(cursor[3] == cursor_char_col, "cursor char col should be " .. cursor_char_col .. ", but was " .. cursor[3])
  assert(vis[2]    == vis_line,        "vis line should be " ..        vis_line ..        ", but was " .. vis[2])
  assert(vis[3]    == vis_char_col,    "vis char col should be " ..    vis_char_col ..    ", but was " .. vis[3])
end

---@param command string
function M.normal(command)
  vim.cmd.normal({ args = {command}, bang = true })
end

---@param file string
function M.edit_file(file)
  vim.cmd.edit({args = {file}, bang=true})
end

function M.switch_visual()
  u.switch_visual()
  floating_window.set_waypoint_for_cursor(nil, true)
end


return M
