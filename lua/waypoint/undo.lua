local M = {}

local config = require"waypoint.config"
local message = require"waypoint.message"
local ring_buffer = require"waypoint.ring_buffer"
local state = require"waypoint.state"
local waypoint_crud = require"waypoint.waypoint_crud"

---@class waypoint.Action
---@field waypoints waypoint.Waypoint[]
---@field undo_msg string
---@field redo_msg string

M.actions = ring_buffer.new(config.max_msg_history)

---@param action waypoint.Action
function M.take_action(action)
  ring_buffer.push(M.messages, action)
end

function M.undo()
  local action, ok = ring_buffer.pop(M.actions)
  if not ok then
    message.notify("At end of undo history", vim.log.levels.INFO)
    return
  end
  state.waypoints = action.waypoints
  waypoint_crud.make_sorted_waypoints()
  message.notify(action.undo_msg, vim.log.levels.INFO)
end

function M.redo()
  local ok = ring_buffer.repush(M.actions)
  if not ok then
    message.notify("At latest change", vim.log.levels.INFO)
    return
  end
  local action, _ = ring_buffer.peek(ring_buffer)
  state.waypoints = action.waypoints
  waypoint_crud.make_sorted_waypoints()
  message.notify(action.redo_msg, vim.log.levels.INFO)
end

return M
