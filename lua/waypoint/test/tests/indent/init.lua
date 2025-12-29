local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json

local config = require"waypoint.config"
local file = require"waypoint.file"
local floating_window = require"waypoint.floating_window"
local state = require"waypoint.state"
local tu = require"waypoint.test.util"
local u = require"waypoint.utils"

describe('Indent', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)
  floating_window.open()

  local lines

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(0, state.waypoints[2].indent)

  floating_window.next_waypoint()
  floating_window.indent()

  local indent
  local indent_str

  indent = 1
  indent_str = string.rep(" ", config.indent_width * indent)

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(indent, state.waypoints[2].indent)
  tu.assert_eq(indent_str, string.sub(lines[2][1], 1, config.indent_width * indent))

  floating_window.indent()

  indent = 2
  indent_str = string.rep(" ", config.indent_width * indent)

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(indent, state.waypoints[2].indent)
  tu.assert_eq(indent_str .. "2", lines[2][1])

  floating_window.unindent()
  floating_window.unindent()
  floating_window.unindent()

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(0, state.waypoints[2].indent)
  tu.assert_eq("2", lines[2][1])

  floating_window.indent()

  indent = 1
  indent_str = string.rep(" ", config.indent_width * indent)

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(indent, state.waypoints[2].indent)
  tu.assert_eq(indent_str .. "2", lines[2][1])

  floating_window.next_waypoint()
  floating_window.indent()
  floating_window.indent()

  indent = 2
  indent_str = string.rep(" ", config.indent_width * indent)

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(indent, state.waypoints[3].indent)
  tu.assert_eq(indent_str .. "3", lines[3][1])

  floating_window.reset_current_indent()

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(0, state.waypoints[3].indent)
  tu.assert_eq("3", lines[3][1])

  floating_window.indent()
  floating_window.reset_all_indent()

  lines = tu.get_waypoint_buffer_lines()
  tu.assert_eq(0, state.waypoints[2].indent)
  tu.assert_eq("2", lines[2][1])
  tu.assert_eq(0, state.waypoints[3].indent)
  tu.assert_eq("3", lines[3][1])
end)
