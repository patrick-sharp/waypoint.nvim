local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local ring_buffer = require("waypoint.ring_buffer")
local state = require("waypoint.state")
local u = require("waypoint.utils")

M.messages = ring_buffer.new(config.max_msg_history)

local sorted_mode_err_msg_table = {"Cannot move waypoints while sort is enabled. Press "}
local toggle_sort = config.keybindings.waypoint_window_keybindings.toggle_sort
u.add_stringifed_keybindings_to_table(sorted_mode_err_msg_table, toggle_sort)
table.insert(sorted_mode_err_msg_table, " to toggle sort")

M.sorted_mode_err_msg = table.concat(sorted_mode_err_msg_table)

local missing_file_err_msg_table = {constants.file_dne_error, ". Press "}
local move_waypoints_to_file = config.keybindings.waypoint_window_keybindings.move_waypoints_to_file
u.add_stringifed_keybindings_to_table(missing_file_err_msg_table, move_waypoints_to_file)
table.insert(missing_file_err_msg_table, " to move this file's waypoint's to a new file")

M.missing_file_err_msg = table.concat(missing_file_err_msg_table)

M.at_earliest_change = "At earliest change"
M.at_latest_change = "At latest change"

---@param file string | nil
function M.restored_before_load(file)
  return "Restored waypoints to before load from file " .. (file or config.file)
end

---@param file string
function M.loaded_file(file)
  return "Loaded waypoints from " .. (file or config.file)
end

---@param path string
---@return string
function M.files_same(path)
   return "Error: " .. path .. " and " .. path .. " are the same"
end

---@param path string
---@return string
function M.file_dne(path)
  return "Error: " .. path .. " does not exist"
end

---@param path string
---@return string
function M.no_waypoints_in_file(path)
  return "Error: no waypoints in file " .. path
end

---@param num_waypoints integer
---@param src string
---@param dst string
---@return string
function M.moved_waypoints_to_file(num_waypoints, src, dst)
  return "Moved " .. tostring(num_waypoints) .. " waypoints from " .. src .. " to " .. dst
end


---@param msg string
function M.from_undo(msg)
  return msg .. " (from undo)"
end

---@param msg string
function M.from_redo(msg)
  return msg .. " (from redo)"
end

---@param position integer
function M.append_waypoint(position)
  return "Appended waypoint at position " .. tostring(position)
end

---@param position integer
function M.insert_waypoint(position)
  return "Inserted waypoint at position " .. tostring(position)
end

---@param position integer
function M.remove_waypoint(position)
  return "Removed waypoint at position " .. tostring(position)
end

---@param position_1 integer | nil
---@param position_2 integer | nil
function M.move_waypoint(position_1, position_2)
  return "Moved waypoint at position " .. tostring(position_1 or "_") .. " to position " .. tostring(position_2 or "_")
end

---@param msg string
---@param level integer | nil
function M.notify(msg, level)
  level = level or vim.log.levels.INFO
  ring_buffer.push(M.messages, {msg = msg, level = level})
  if state.should_notify ~= false then
    vim.notify(msg, level)
  end
end

return M
