local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

describe('Delete', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)
  floating_window.open()

  local lines
  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(test_list.num_waypoints, u.len(lines))

  floating_window.next_waypoint()
  floating_window.delete_current_waypoint()

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(2, u.len(lines))

  local wp_1_lnum_str = tostring(test_list.wp_1_lnum)
  local wp_3_lnum_str = tostring(test_list.wp_3_lnum)

  tu.assert_eq(test_list.file_0,    lines[1][2])
  tu.assert_eq(wp_1_lnum_str,       lines[1][3])
  tu.assert_eq(test_list.wp_1_text, lines[1][4])

  tu.assert_eq(test_list.file_1,    lines[2][2])
  tu.assert_eq(wp_3_lnum_str,       lines[2][3])
  tu.assert_eq(test_list.wp_3_text, lines[2][4])

  floating_window.delete_current_waypoint()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(1, u.len(lines))
  tu.assert_eq(test_list.file_0,    lines[1][2])
  tu.assert_eq(wp_1_lnum_str,       lines[1][3])
  tu.assert_eq(test_list.wp_1_text, lines[1][4])

  floating_window.delete_current_waypoint()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(1, u.len(lines))
  tu.assert_eq(0, u.len(lines[1]))
end)
