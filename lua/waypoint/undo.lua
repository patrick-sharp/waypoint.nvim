local M = {}

local config = require"waypoint.config"

---@class waypoint.UndoNode
---@field waypoints waypoint.Waypoint[]
---@field undo_msg string
---@field redo_msg string

local action_idx = 1
local latest_action_idx = nil
local earliest_action_idx = nil
local actions = {}

function M.push(waypoints, undo_msg, redo_msg)
  actions[action_idx] = {
    waypoints = waypoints,
    undo_msg = undo_msg,
    redo_msg = redo_msg,
  }
  latest_action_idx = action_idx
  local next_action_idx = (action_idx + 1) % config.max_undo_history
  if earliest_action_idx == nil then
    earliest_action_idx = 1
  elseif action_idx == earliest_action_idx then
    earliest_action_idx = next_action_idx
  end
  action_idx = next_action_idx
end

function M.undo()
  if latest_action_idx == nil then
    -- no actions in undo history
  elseif action_idx == earliest_action_idx then
    -- at earliest action in undo history
  end
end

function M.redo()
  if latest_action_idx == nil then
    -- no actions in undo history
  elseif action_idx == latest_action_idx then
    -- at latest action in undo history
  end
end

return M
