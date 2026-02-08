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
describe('Visual move', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_move/waypoints.json"
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

  assert(not uw.should_draw_waypoint(state.waypoints[1]))
  assert(uw.should_draw_waypoint(state.waypoints[2]))
  assert(uw.should_draw_waypoint(state.waypoints[3]))
  assert(not uw.should_draw_waypoint(state.waypoints[4]))
  assert(uw.should_draw_waypoint(state.waypoints[5]))
  assert(uw.should_draw_waypoint(state.waypoints[6]))
  assert(not uw.should_draw_waypoint(state.waypoints[7]))

  floating_window.open()

  local lines

  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(4, #lines)

  for _=1,10 do
    floating_window.next_waypoint()
  end

  -- test you can't scroll off the bottom
  tu.assert_eq(6, state.wpi)

  -- select last three
  u.enter_visual_mode()
  floating_window.prev_waypoint()
  floating_window.prev_waypoint()

  tu.assert_eq(3, state.wpi)
  tu.assert_eq(6, state.vis_wpi)

  -- move down (nothing changes)
  floating_window.move_waypoint_down()
  tu.assert_eq(3, state.wpi)
  tu.assert_eq(6, state.vis_wpi)
  for i=1,#waypoints do
    tu.assert_waypoints_eq(waypoints[i], state.waypoints[i])
  end

  -- move up 1 (wp 2 moves to bottom)
  floating_window.move_waypoint_up()
  tu.assert_eq(2, state.wpi)
  tu.assert_eq(5, state.vis_wpi)
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])

  -- shrink top of selection, move down 1 (wp 2 moves to position 5)
  floating_window.next_waypoint()
  floating_window.move_waypoint_down()
  tu.assert_eq(5, state.wpi)
  tu.assert_eq(6, state.vis_wpi)
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])

  -- undo
  u.exit_visual_mode()
  floating_window.undo()
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])

  -- redo
  floating_window.redo()
  tu.assert_waypoints_eq(waypoints[1], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[3])
  tu.assert_waypoints_eq(waypoints[4], state.waypoints[4])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[5])
  tu.assert_waypoints_eq(waypoints[6], state.waypoints[6])
  tu.assert_waypoints_eq(waypoints[7], state.waypoints[7])
end)
