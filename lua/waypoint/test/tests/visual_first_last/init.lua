local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local waypoints_json = "lua/waypoint/test/tests/visual_first_last/waypoints.json"

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'

describe('Visual first last', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

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
  floating_window.next_waypoint()
  tu.assert_eq(3, state.wpi)
  floating_window.next_waypoint()
  tu.assert_eq(5, state.wpi)
  u.enter_visual_mode()
  floating_window.move_to_first_waypoint()
  tu.assert_eq(2, state.wpi)
  tu.assert_eq(5, state.vis_wpi)
  tu.switch_visual()
  floating_window.prev_waypoint()
  tu.switch_visual()
  tu.assert_eq(2, state.wpi)
  tu.assert_eq(3, state.vis_wpi)

  floating_window.move_to_last_waypoint()
  tu.assert_eq(6, state.wpi)
  tu.assert_eq(3, state.vis_wpi)
  tu.switch_visual()
  tu.assert_eq(3, state.wpi)
  tu.assert_eq(6, state.vis_wpi)
end)
