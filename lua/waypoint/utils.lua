local M = {}

local state = require("waypoint.state")
local constants = require("waypoint.constants")

function M.get_in(t, keys)
  local cur = t
  for _, k in ipairs(keys) do
    if not cur[k] then
      return nil
    end
    cur = cur[k]
  end
  return cur
end


function M.set_in(t, keys, value)
  if #keys == 0 then
    return
  end

  local cur = t
  for i = 1, #keys - 1 do
    local k = keys[i]
    if not cur[k] then
      cur[k] = {}
    end
    cur = cur[k]
  end

  cur[keys[#keys]] = value
end


function M.delete_in(t, keys)
  if #keys == 0 then
    return
  end

  local cur = t
  for i = 1, #keys - 1 do
    local k = keys[i]
    if not cur[k] then
      return
    end
    cur = cur[k]
  end

  cur[keys[#keys]] = nil
end

function M.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end


function M.buf_find_waypoint(line_nr)
  -- note that this is just for the current buffer
  local marks = vim.api.nvim_buf_get_extmarks(0, constants.ns, 0, -1, {})
  for i, mark in ipairs(marks) do
    local extmark_row = mark[2] + 1 -- have to do this because extmark line numbers are 0 indexed
    if extmark_row == line_nr then
      return i
    end
  end
  return -1
end

--- @param waypoint Waypoint
--- @return { [1]: integer, [2]: integer }
function M.extmark_for_waypoint(waypoint)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
  --- @type { [1]: integer, [2]: integer }
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
  return extmark
end

--- @param waypoint Waypoint
--- @return { [1]: integer, [2]: integer }, string
function M.extmark_line_for_waypoint(waypoint)
  local bufnr = vim.fn.bufnr(waypoint.filepath)
  --- @type { [1]: integer, [2]: integer }
  local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
  local lines = vim.api.nvim_buf_get_lines(bufnr, extmark[1], extmark[1] + 1, true)
  local line = lines[1]
  return extmark, line
end

function M.clamp(x, min, max)
  if x < min then
    return min
  elseif x > max then
    return max
  end
  return x
end



return M
