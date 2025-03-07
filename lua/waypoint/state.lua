-- This file keeps track of where all the waypoints are and the state of the floating window

---@class Waypoint
---@field annotation string | nil
---@field extmark_id integer
---@field filepath string
---@field indent integer

---@class State
---@field wpi integer | nil
---@field waypoints table<Waypoint>
---@field context integer
---@field before_context integer
---@field after_context integer

-- TODO:
-- state should be a table of extmark ids, and just use the extmarks to maintain state

---@type State
local M = {
  wpi = nil,
  waypoints = {},
  context = 0,
  before_context = 0,
  after_context = 0,
  scroll_col = 0,
}

return M
