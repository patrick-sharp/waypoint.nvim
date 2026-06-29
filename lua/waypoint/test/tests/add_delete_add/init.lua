local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local crud = require("waypoint.waypoint_crud")
local state = require("waypoint.state")
local u = require("waypoint.util")
local tu = require'waypoint.test.util'

describe('Add delete add', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))

  tu.edit_file(file_0)
  u.goto_line(7)

  tu.assert_eq(0, #state.waypoints)
  tu.assert_eq(nil, state.wpi)

  crud.append_waypoint_wrapper()
  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(1, state.wpi)

  crud.append_waypoint_wrapper()
  tu.assert_eq(2, #state.waypoints)
  tu.assert_eq(2, state.wpi)

  crud.delete_waypoint()
  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(1, state.wpi)

  crud.append_waypoint_wrapper()
  tu.assert_eq(2, #state.waypoints)
  tu.assert_eq(2, state.wpi)
end)
