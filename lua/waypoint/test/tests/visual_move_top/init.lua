local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'
local uw = require'waypoint.utils_waypoint'

-- this test also tests waypoints not displaying when their extmarks are deleted
describe('Visual move top', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_move_top/waypoints.json"
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  local waypoints = vim.deepcopy(state.waypoints)

  -- delete the middle waypoint
  tu.edit_file(file_0)
  u.goto_line(4)
  tu.normal("dd")

  -- delete the first waypoint
  u.goto_line(1)
  tu.normal("dd")

  -- delete the last waypoint
  tu.edit_file(file_1)
  u.goto_line(9)
  tu.normal("dd")

  floating_window.open()

  local lines

  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(4, #lines)

  u.enter_visual_mode()
  floating_window.on_mode_change(true)
  floating_window.draw_waypoint_window()
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  tu.assert_eq(5, state.wpi)
  tu.assert_eq(2, state.vis_wpi)

  -- move top (does nothing)
  floating_window.move_waypoint_to_top()
  tu.assert_eq(5, state.wpi)
  tu.assert_eq(2, state.vis_wpi)
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])

  -- move middle
  tu.switch_visual()
  floating_window.next_waypoint()
  floating_window.move_waypoint_to_top()
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])

  -- move bottom
  floating_window.move_to_last_waypoint()
  floating_window.move_waypoint_to_top()
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])

  -- undo
  floating_window.undo()
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])

  -- redo
  floating_window.redo()
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])
end)
