local M = {}

---@class waypoint.Timer
---@field start_time_millis number
local Timer = { start_time_millis = 0 }
Timer.__index = Timer

function M.start()
  ---@type waypoint.Timer
  local self = setmetatable({}, Timer)

  self.start_time_millis = vim.uv.hrtime() / 1e6

  return self
end

function Timer:reset()
  self.start_time_millis = vim.uv.hrtime() / 1e6
end

---@return number
function Timer:stop()
  local end_time_millis = vim.uv.hrtime() / 1e6
  return end_time_millis - self.start_time_millis
end

return M
