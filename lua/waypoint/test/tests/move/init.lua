local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json

local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

describe('Move', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)
  floating_window.open()

  local lines

  lines = tu.get_waypoint_buffer_lines_trimmed()

  local wp_1_text = "local M = {}"
  local wp_2_text = "table.insert(t, i)"
  local wp_3_text = "end"

  tu.assert_eq(wp_1_text, lines[1][4])
  tu.assert_eq(wp_2_text, lines[2][4])
  tu.assert_eq(wp_3_text, lines[3][4])

  tu.assert_eq(1, state.wpi)

  floating_window.move_waypoint_down()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_2_text, lines[1][4])
  tu.assert_eq(wp_1_text, lines[2][4])
  tu.assert_eq(wp_3_text, lines[3][4])

  floating_window.move_waypoint_down()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_2_text, lines[1][4])
  tu.assert_eq(wp_3_text, lines[2][4])
  tu.assert_eq(wp_1_text, lines[3][4])

  floating_window.move_waypoint_down()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_2_text, lines[1][4])
  tu.assert_eq(wp_3_text, lines[2][4])
  tu.assert_eq(wp_1_text, lines[3][4])

  floating_window.prev_waypoint()
  floating_window.move_waypoint_up()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_3_text, lines[1][4])
  tu.assert_eq(wp_2_text, lines[2][4])
  tu.assert_eq(wp_1_text, lines[3][4])

  floating_window.move_waypoint_up()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_3_text, lines[1][4])
  tu.assert_eq(wp_2_text, lines[2][4])
  tu.assert_eq(wp_1_text, lines[3][4])

  floating_window.next_waypoint()
  floating_window.move_waypoint_down()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_3_text, lines[1][4])
  tu.assert_eq(wp_1_text, lines[2][4])
  tu.assert_eq(wp_2_text, lines[3][4])
end)
