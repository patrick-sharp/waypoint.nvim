local M = {}

local config = require"waypoint.config"
local message = require"waypoint.message"
local ring_buffer = require"waypoint.ring_buffer"
local state = require"waypoint.state"
local u = require"waypoint.utils"
local uw = require"waypoint.utils_waypoint"
local constants = require"waypoint.constants"

---@class waypoint.UndoNode
---@field waypoints waypoint.Waypoint[]
---@field wpi integer | nil
---@field undo_msg string
---@field redo_msg string

-- we will always keep at least one state in this ring buffer.
-- when you undo, load the previous state and previous wpi.
-- when you just loaded the first state in the ring buffer, there is no 
-- previous state. Having zero states in the ring buffer is an unrepresentable
-- null state that would mean not only having no previous state, but no current
-- state either.
-- when you redo, load the next state. if you're at the latest state, there is
-- no next state
M.states = ring_buffer.new(config.max_msg_history)

---@param undo_msg string
---@param redo_msg string
---@param change_wpi integer | nil
function M.save_state(undo_msg, redo_msg, change_wpi)
  message.notify(redo_msg, vim.log.levels.INFO)

  ---@type waypoint.UndoNode
  local undo_node = {
    waypoints = u.deep_copy(state.waypoints),
    wpi = change_wpi or state.wpi,
    undo_msg = undo_msg,
    redo_msg = redo_msg,
  }

  ring_buffer.push(M.states, undo_node)
end

-- if any extmarks in state are missing, replace them.
-- if any extmarks are present with no waypoint, remove them
-- if any extmarks don't match their waypoint's line number, move them
function M.set_extmarks_for_state()
  ---@type table<integer,waypoint.Waypoint[]>
  local bufnr_to_waypoints = {}
  for _,wp in ipairs(state.waypoints) do
    if wp.bufnr ~= -1 and 0 ~= vim.fn.bufloaded(wp.bufnr) then
      local waypoints = bufnr_to_waypoints[wp.bufnr] or {}
      bufnr_to_waypoints[wp.bufnr] = waypoints
      waypoints[#waypoints+1] = wp
    else
      wp.bufnr = -1
    end
  end
  for bufnr,waypoints in pairs(bufnr_to_waypoints) do
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, constants.ns, 0, -1, {})
    for _,extmark in ipairs(extmarks) do
      local extmark_id = extmark[1]
      vim.api.nvim_buf_del_extmark(bufnr, constants.ns, extmark_id)
    end
    for _,waypoint in ipairs(waypoints) do
      uw.set_extmark(waypoint)
    end
  end
end

---@return boolean
function M.undo()
  if M.states.size == 1 then
    message.notify(constants.msg_at_earliest_change, vim.log.levels.INFO)
    return false
  end

  local curr_state, prev_state, ok

  curr_state, ok = ring_buffer.peek(M.states)
  assert(ok)
  _, ok = ring_buffer.pop(M.states)
  assert(ok)
  prev_state, ok = ring_buffer.peek(M.states)
  assert(ok)

  state.waypoints = u.deep_copy(prev_state.waypoints)
  state.wpi = prev_state.wpi
  uw.make_sorted_waypoints()
  M.set_extmarks_for_state()
  message.notify(curr_state.undo_msg .. " (from undo)", vim.log.levels.INFO)
  return true
end

---@return boolean
function M.redo()
  local ok = ring_buffer.repush(M.states)
  if not ok then
    message.notify("At latest change", vim.log.levels.INFO)
    return false
  end
  local next_state, _ = ring_buffer.peek(M.states)
  state.waypoints = u.deep_copy(next_state.waypoints)
  state.wpi = next_state.wpi
  uw.make_sorted_waypoints()
  M.set_extmarks_for_state()
  message.notify(next_state.redo_msg .. " (from redo)", vim.log.levels.INFO)
  return true
end

return M
