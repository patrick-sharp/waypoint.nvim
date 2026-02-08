local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'

describe('Visual indent', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  floating_window.open()

  -- indent one waypoint
  u.enter_visual_mode()
  floating_window.draw_waypoint_window()
  floating_window.indent()
  tu.assert_eq(1, state.waypoints[1].indent)
  tu.assert_eq(0, state.waypoints[2].indent)
  tu.assert_eq(0, state.waypoints[3].indent)

  -- indent two waypoints
  floating_window.next_waypoint()
  floating_window.indent()
  tu.assert_eq(2, state.waypoints[1].indent)
  tu.assert_eq(1, state.waypoints[2].indent)
  tu.assert_eq(0, state.waypoints[3].indent)

  -- indent three waypoints
  floating_window.next_waypoint()
  floating_window.indent()
  tu.assert_eq(3, state.waypoints[1].indent)
  tu.assert_eq(2, state.waypoints[2].indent)
  tu.assert_eq(1, state.waypoints[3].indent)

  u.exit_visual_mode()
  floating_window.draw_waypoint_window()
  u.enter_visual_mode()
  floating_window.move_to_first_waypoint()
  floating_window.next_waypoint()
  floating_window.indent()
  tu.assert_eq(3, state.waypoints[1].indent)
  tu.assert_eq(3, state.waypoints[2].indent)
  tu.assert_eq(2, state.waypoints[3].indent)

  floating_window.next_waypoint()
  floating_window.indent()
  floating_window.indent()
  tu.assert_eq(3, state.waypoints[1].indent)
  tu.assert_eq(3, state.waypoints[2].indent)
  tu.assert_eq(4, state.waypoints[3].indent)

  u.exit_visual_mode()
  floating_window.draw_waypoint_window()
  floating_window.prev_waypoint()
  floating_window.leave()
  tu.edit_file(file_1)
  u.goto_line(8)
  tu.normal("dd")
  floating_window.open()
  floating_window.move_to_last_waypoint()
  floating_window.indent()
  u.enter_visual_mode()
  floating_window.prev_waypoint()
  floating_window.unindent()
  floating_window.unindent()
  floating_window.unindent()
  floating_window.unindent()
  tu.assert_eq(0, state.waypoints[1].indent)
  tu.assert_eq(3, state.waypoints[2].indent)
  tu.assert_eq(1, state.waypoints[3].indent)
end)
