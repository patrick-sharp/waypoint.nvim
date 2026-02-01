local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'

describe('Visual delete', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_delete/waypoints.json"
  local num_waypoints = 6
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  local waypoints = vim.deepcopy(state.waypoints)

  floating_window.open()

  local lines
  local num_deleted = 0

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(num_waypoints, u.len(lines))

  -- delete one waypoint
  u.enter_visual_mode()
  floating_window.delete_curr()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  num_deleted = 1
  tu.assert_eq(num_waypoints - num_deleted, u.len(lines))
  tu.assert_eq(num_waypoints - num_deleted, #state.waypoints)
  tu.assert_eq(num_waypoints - num_deleted, #state.sorted_waypoints)
  tu.assert_eq(false, u.is_in_visual_mode())
  tu.assert_eq(1, state.wpi)

  for i = 1, num_waypoints - 1 do
    tu.assert_waypoints_eq(waypoints[i+1], state.waypoints[i])
  end

  -- delete two waypoints
  u.enter_visual_mode()
  floating_window.next_waypoint()
  floating_window.delete_curr()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  num_deleted = num_deleted + 2
  tu.assert_eq(num_waypoints - num_deleted, u.len(lines))
  tu.assert_eq(num_waypoints - num_deleted, #state.waypoints)
  tu.assert_eq(num_waypoints - num_deleted, #state.sorted_waypoints)
  for i = 1, num_waypoints - num_deleted do
    tu.assert_waypoints_eq(waypoints[i+3], state.waypoints[i])
  end

  -- delete remaining waypoints
  u.enter_visual_mode()
  floating_window.move_to_last_waypoint()
  floating_window.delete_curr()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(1, u.len(lines)) -- every buffer has at least one line
  tu.assert_eq(nil, state.wpi)
  tu.assert_eq(0, #state.waypoints)
  tu.assert_eq(0, #state.sorted_waypoints)
end)
