local M = {}

local config = require"waypoint.config"
local message = require"waypoint.message"
local ring_buffer = require"waypoint.ring_buffer"
local state = require"waypoint.state"
local u = require"waypoint.utils"
local uw = require"waypoint.utils_waypoint"

---@class waypoint.UndoNode
---@field waypoints waypoint.UndoNodeWaypoint[]
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

---@return waypoint.UndoNodeWaypoint[]
function M.undo_node_waypoints_from_waypoints()
  ---@type waypoint.UndoNodeWaypoint[]
  local result = {}

  for _,wp in ipairs(state.waypoints) do
    local linenr = wp.linenr or uw.linenr_from_waypoint(wp)
    assert(linenr)

    result[#result+1] = {
      indent     = wp.indent,
      annotation = wp.annotation,
      bufnr      = wp.bufnr,
      extmark_id = wp.extmark_id,
      filepath   = wp.filepath or u.path_from_buf(wp.bufnr),
      text       = wp.text or u.get_line_text(wp.bufnr, linenr),
      linenr     = linenr,
    }
  end

  return result
end

---@param undo_node_waypoints waypoint.UndoNodeWaypoint[]
---@return waypoint.Waypoint[]
function M.waypoints_from_undo_node_waypoints(undo_node_waypoints)
  ---@type waypoint.Waypoint[]
  local result = {}

  for _, wp in ipairs(undo_node_waypoints) do
    local linenr = wp.linenr or uw.linenr_from_extmark_id(wp.extmark_id)
    assert(linenr)

    local has_buffer = u.is_buffer_valid(wp.bufnr)

    result[#result+1] = {
      has_buffer = has_buffer,
      indent     = wp.indent,
      annotation = wp.annotation,
      bufnr      = has_buffer and wp.bufnr or nil,
      extmark_id = has_buffer and wp.extmark_id or nil,
      filepath   = (not has_buffer) and wp.filepath or nil,
      text       = (not has_buffer) and wp.text or nil,
      linenr     = (not has_buffer) and linenr or nil,
    }
  end

  return result
end

---@param undo_msg string
---@param redo_msg string
---@param change_wpi integer | nil
function M.save_state(undo_msg, redo_msg, change_wpi)
  message.notify(redo_msg, vim.log.levels.INFO)

  ---@type waypoint.UndoNode
  local undo_node = {
    waypoints = M.undo_node_waypoints_from_waypoints(),
    wpi = change_wpi or state.wpi,
    undo_msg = undo_msg,
    redo_msg = redo_msg,
  }

  ring_buffer.push(M.states, undo_node)
end

-- hide extmarks that don't have a drawn waypoint.
-- show extmarks that do
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
  -- hide all extmarks, then re-show the ones whose waypoints are in the current state
  for bufnr,waypoints in pairs(bufnr_to_waypoints) do
    uw.buf_hide_extmarks(bufnr)
    for _,waypoint in ipairs(waypoints) do
      if uw.should_draw_waypoint(waypoint) then
        uw.set_wp_extmark_visible(waypoint, true)
      end
    end
  end
end

---@return boolean
function M.undo()
  if M.states.size == 1 then
    message.notify(message.at_earliest_change, vim.log.levels.INFO)
    return false
  end

  local curr_state, prev_state, ok

  curr_state, ok = ring_buffer.peek(M.states)
  assert(ok)
  _, ok = ring_buffer.pop(M.states)
  assert(ok)
  prev_state, ok = ring_buffer.peek(M.states)
  assert(ok)

  state.waypoints = M.waypoints_from_undo_node_waypoints(prev_state.waypoints)
  state.wpi = prev_state.wpi
  uw.make_sorted_waypoints()
  M.set_extmarks_for_state()
  message.notify(message.from_undo(curr_state.undo_msg), vim.log.levels.INFO)
  return true
end

---@return boolean
function M.redo()
  local ok = ring_buffer.repush(M.states)
  if not ok then
    message.notify(message.at_latest_change, vim.log.levels.INFO)
    return false
  end
  local next_state, _ = ring_buffer.peek(M.states)
  state.waypoints = M.waypoints_from_undo_node_waypoints(next_state.waypoints)
  state.wpi = next_state.wpi
  uw.make_sorted_waypoints()
  M.set_extmarks_for_state()
  message.notify(message.from_redo(next_state.redo_msg), vim.log.levels.INFO)
  return true
end

-- clears the undo history.
-- note that generally I make the assumption that the undo buffer always has at
-- least one element in it at all time, so I call save_state here to ensure that.
function M.clear()
  ring_buffer.clear(M.states)
  M.save_state("", "")
end

return M
