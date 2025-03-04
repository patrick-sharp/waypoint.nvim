-- This file keeps track of where all the waypoints are
--
---@class Waypoint
---@field filepath string
---@field line_nr integer
---@field line_text string
---@field annotation string
---@field icon string | nil
---@field extmark_id any

---@class WindowState
---@field current_waypoint integer | nil
---@field waypoints table<Waypoint>
---@field context integer
---@field before_context integer
---@field after_context integer

---@class State
---@field waypoints table<string, table<integer, Waypoint>> The keys are filepaths relative to the current directory, the values are tables. In those tables, the keys are line numbers and the values are waypoints
---@field window WindowState

---@type State
local M = {
  waypoints = {},
  window = {
    current_waypoint = nil,
    waypoints = {},
    context = 0,
    before_context = 0,
    after_context = 0,
  }
}

return M
