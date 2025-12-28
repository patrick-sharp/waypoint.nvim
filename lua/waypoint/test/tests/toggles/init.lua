local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json
local wp_1_text = test_list.wp_1_text
local wp_2_text = test_list.wp_2_text
local wp_3_text = test_list.wp_3_text

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

describe('Toggles', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  local basename_0 = vim.fs.basename(file_0)
  local basename_1 = vim.fs.basename(file_1)

  file.load_from_file(waypoints_json)
  floating_window.open()

  local lines

  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(4, #lines[1])
  tu.assert_eq("1",                  lines[1][1])
  tu.assert_eq(file_0,               lines[1][2])
  tu.assert_eq("1",                  lines[1][3])
  tu.assert_eq(wp_1_text,            lines[1][4])

  tu.assert_eq(4, #lines[2])
  tu.assert_eq("2",                  lines[2][1])
  tu.assert_eq(file_1,               lines[2][2])
  tu.assert_eq("8",                  lines[2][3])
  tu.assert_eq(wp_2_text, lines[2][4])

  tu.assert_eq(4, #lines[3])
  tu.assert_eq("3",                  lines[3][1])
  tu.assert_eq(file_1,               lines[3][2])
  tu.assert_eq("9",                  lines[3][3])
  tu.assert_eq(wp_3_text,            lines[3][4])

  floating_window.toggle_text()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(3, #lines[1])
  tu.assert_eq("1",                  lines[1][1])
  tu.assert_eq(file_0,               lines[1][2])
  tu.assert_eq("1",                  lines[1][3])

  tu.assert_eq(3, #lines[2])
  tu.assert_eq("2",                  lines[2][1])
  tu.assert_eq(file_1,               lines[2][2])
  tu.assert_eq("8",                  lines[2][3])

  tu.assert_eq(3, #lines[3])
  tu.assert_eq("3",                  lines[3][1])
  tu.assert_eq(file_1,               lines[3][2])
  tu.assert_eq("9",                  lines[3][3])

  floating_window.toggle_full_path()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(3, #lines[1])
  tu.assert_eq("1",                  lines[1][1])
  tu.assert_eq(basename_0,           lines[1][2])
  tu.assert_eq("1",                  lines[1][3])

  tu.assert_eq(3, #lines[2])
  tu.assert_eq("2",                  lines[2][1])
  tu.assert_eq(basename_1,           lines[2][2])
  tu.assert_eq("8",                  lines[2][3])

  tu.assert_eq(3, #lines[3])
  tu.assert_eq("3",                  lines[3][1])
  tu.assert_eq(basename_1,           lines[3][2])
  tu.assert_eq("9",                  lines[3][3])

  floating_window.toggle_path()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(2, #lines[1])
  tu.assert_eq("1",                  lines[1][1])
  tu.assert_eq("1",                  lines[1][2])

  tu.assert_eq(2, #lines[2])
  tu.assert_eq("2",                  lines[2][1])
  tu.assert_eq("8",                  lines[2][2])

  tu.assert_eq(2, #lines[3])
  tu.assert_eq("3",                  lines[3][1])
  tu.assert_eq("9",                  lines[3][2])

  floating_window.toggle_line_number()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(1, #lines[1])
  tu.assert_eq("1",                  lines[1][1])

  tu.assert_eq(1, #lines[2])
  tu.assert_eq("2",                  lines[2][1])

  tu.assert_eq(1, #lines[3])
  tu.assert_eq("3",                  lines[3][1])

  floating_window.toggle_text()
  floating_window.toggle_full_path()
  floating_window.toggle_path()
  floating_window.toggle_line_number()

  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(4, #lines[1])
  tu.assert_eq("1",                  lines[1][1])
  tu.assert_eq(file_0,               lines[1][2])
  tu.assert_eq("1",                  lines[1][3])
  tu.assert_eq(wp_1_text,            lines[1][4])

  tu.assert_eq(4, #lines[2])
  tu.assert_eq("2",                  lines[2][1])
  tu.assert_eq(file_1,               lines[2][2])
  tu.assert_eq("8",                  lines[2][3])
  tu.assert_eq(wp_2_text,            lines[2][4])

  tu.assert_eq(4, #lines[3])
  tu.assert_eq("3",                  lines[3][1])
  tu.assert_eq(file_1,               lines[3][2])
  tu.assert_eq("9",                  lines[3][3])
  tu.assert_eq(wp_3_text,            lines[3][4])

  floating_window.increase_context()

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(11, #lines)

  floating_window.toggle_context()

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(3, #lines)

  floating_window.toggle_context()

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(11, #lines)
end)
