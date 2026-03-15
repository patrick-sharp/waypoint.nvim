local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local crud = require("waypoint.waypoint_crud")
local file = require'waypoint.file'
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

local waypoints_json = "lua/waypoint/test/tests/undo_with_errors/waypoints.json"

-- undo and redo several operations with erroneous waypoints in the window
describe('Undo with errors', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  tu.edit_file(file_0)
  u.goto_line(4)
  crud.append_waypoint_wrapper()
  u.goto_line(17)
  crud.append_waypoint_wrapper()

  tu.assert_eq(8, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("nil", type(state.waypoints[2].error))
  tu.assert_eq("string", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))
  tu.assert_eq("string", type(state.waypoints[6].error))
  tu.assert_eq("nil", type(state.waypoints[7].error))
  tu.assert_eq("nil", type(state.waypoints[8].error))

  floating_window.open()
  floating_window.undo()
  floating_window.undo()

  tu.assert_eq(6, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("nil", type(state.waypoints[2].error))
  tu.assert_eq("string", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))
  tu.assert_eq("string", type(state.waypoints[6].error))

  floating_window.redo()

  tu.assert_eq(7, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("nil", type(state.waypoints[2].error))
  tu.assert_eq("string", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))
  tu.assert_eq("string", type(state.waypoints[6].error))
  tu.assert_eq("nil", type(state.waypoints[7].error))

  floating_window.next_waypoint()
  floating_window.next_waypoint()
  floating_window.delete()
  floating_window.delete()

  tu.assert_eq(5, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("nil", type(state.waypoints[2].error))
  tu.assert_eq("string", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))

  floating_window.undo()

  tu.assert_eq(6, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("nil", type(state.waypoints[2].error))
  tu.assert_eq("string", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))
  tu.assert_eq("string", type(state.waypoints[6].error))

  floating_window.move_to_first_waypoint()
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  tu.enter_visual_mode()
  floating_window.prev_waypoint()
  floating_window.prev_waypoint()
  floating_window.move_waypoint_up()

  tu.assert_eq(6, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("string", type(state.waypoints[2].error))
  tu.assert_eq("nil", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))
  tu.assert_eq("string", type(state.waypoints[6].error))

  floating_window.undo()

  tu.assert_eq(6, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("nil", type(state.waypoints[2].error))
  tu.assert_eq("string", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))
  tu.assert_eq("string", type(state.waypoints[6].error))

  floating_window.redo()

  tu.assert_eq(6, #state.waypoints)
  tu.assert_eq("string", type(state.waypoints[1].error))
  tu.assert_eq("string", type(state.waypoints[2].error))
  tu.assert_eq("nil", type(state.waypoints[3].error))
  tu.assert_eq("nil", type(state.waypoints[4].error))
  tu.assert_eq("nil", type(state.waypoints[5].error))
  tu.assert_eq("string", type(state.waypoints[6].error))
end)
