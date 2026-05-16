local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local waypoints_json = "lua/waypoint/test/tests/move_to_waypoint/waypoints.json"

local floating_window = require"waypoint.floating_window"
local file = require'waypoint.file'
local u = require"waypoint.util"
local tu = require'waypoint.test.util'
local state = require'waypoint.state'

describe('Move to waypoint', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  -- create an undrawn waypoint by deleting waypoint 3's line
  tu.edit_file(file_0)
  u.goto_line(8)
  tu.normal('dd')

  floating_window.open()

  -- now there should be 5 waypoints in total, 4 drawn

  -- default to last line
  floating_window.move_to_waypoint()
  tu.assert_eq(#state.waypoints, state.wpi)

  ---@type string

  floating_window.move_to_waypoint(3)
  tu.assert_eq(4, state.wpi)

  floating_window.move_to_waypoint(1)
  tu.assert_eq(1, state.wpi)

  floating_window.move_to_waypoint(2)
  tu.assert_eq(3, state.wpi)

  floating_window.move_to_waypoint(4)
  tu.assert_eq(5, state.wpi)

  floating_window.move_to_waypoint(10000)
  tu.assert_eq(5, state.wpi)


  -- now try it with sort
  floating_window.toggle_sort()

  floating_window.move_to_waypoint(3)
  tu.assert_eq(3, state.wpi)

  floating_window.move_to_waypoint(1)
  tu.assert_eq(1, state.wpi)

  floating_window.move_to_waypoint(2)
  tu.assert_eq(2, state.wpi)

  floating_window.move_to_waypoint(4)
  tu.assert_eq(5, state.wpi)

  floating_window.move_to_waypoint(10000)
  tu.assert_eq(5, state.wpi)
end)
