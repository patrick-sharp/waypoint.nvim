local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local file = require'waypoint.file'
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local tu = require("waypoint.test.util")

describe('Context', function()
  floating_window.open()
  file.load_from_file(test_list.waypoints_json)

  floating_window.increase_after_context()
  assert(state.after_context == 1)
  floating_window.increase_before_context()
  assert(state.before_context == 1)
  floating_window.increase_context()
  assert(state.context == 1)

  floating_window.decrease_after_context()
  assert(state.after_context == 0)
  floating_window.decrease_before_context()
  assert(state.before_context == 0)
  floating_window.decrease_context()
  assert(state.context == 0)

  floating_window.decrease_after_context()
  assert(state.after_context == 0)
  floating_window.decrease_before_context()
  assert(state.before_context == 0)
  floating_window.decrease_context()
  assert(state.context == 0)

  local a = 4
  local b = 2
  local c = 1

  for _= 1,a do floating_window.increase_after_context() end
  for _= 1,b do floating_window.increase_before_context() end
  for _= 1,c do floating_window.increase_context() end

  local lines
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(a, state.after_context)
  tu.assert_eq(b, state.before_context)
  tu.assert_eq(c, state.context)

  local num_waypoint_lines = test_list.num_waypoints * (a + b + c * 2 + 1)
  local num_separator_lines = test_list.num_waypoints - 1
  local num_lines = num_waypoint_lines + num_separator_lines

  tu.assert_eq(num_lines, #lines)

  floating_window.reset_context()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(test_list.num_waypoints, #lines)
end)
