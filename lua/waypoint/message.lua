local M = {}

local config = require("waypoint.config")
local u = require("waypoint.utils")

local sorted_mode_err_msg_table = {"Cannot move waypoints while sort is enabled. Press "}
local toggle_sort = config.keybindings.waypoint_window_keybindings.toggle_sort
u.add_stringifed_keybindings_to_table(sorted_mode_err_msg_table, toggle_sort)
table.insert(sorted_mode_err_msg_table, " to toggle sort")
M.sorted_mode_err_msg = table.concat(sorted_mode_err_msg_table)

local missing_file_err_msg_table = {"Cannot go to waypoint in missing file. Press "}
local move_waypoints_to_file = config.keybindings.waypoint_window_keybindings.move_waypoints_to_file
u.add_stringifed_keybindings_to_table(missing_file_err_msg_table, move_waypoints_to_file)
table.insert(missing_file_err_msg_table, " to fix")
M.missing_file_err_msg = table.concat(missing_file_err_msg_table)

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

return M
