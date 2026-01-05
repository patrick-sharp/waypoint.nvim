local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0

local crud = require("waypoint.waypoint_crud")
local floating_window = require("waypoint.floating_window")
local message = require'waypoint.message'
local state = require("waypoint.state")
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

describe('Undo insert', function()
  assert(u.file_exists(file_0))

  floating_window.open()
  floating_window.undo()
  floating_window.close()

  tu.assert_eq(message.at_earliest_change, tu.get_last_message())

  floating_window.open()
  floating_window.redo()
  floating_window.close()

  tu.assert_eq(message.at_latest_change, tu.get_last_message())

  vim.cmd.edit({args = {file_0}, bang=true})
  tu.goto_line(7)
  crud.insert_waypoint_wrapper()

  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(7, state.waypoints[1].linenr)

  floating_window.open()
  floating_window.undo()
  local undo_msg = message.from_undo(message.remove_waypoint(1))
  tu.assert_eq(undo_msg, tu.get_last_message())
  tu.assert_eq(0, #state.waypoints)
  tu.assert_eq(nil, state.wpi)

  floating_window.undo()
  tu.assert_eq(message.at_earliest_change, tu.get_last_message())

  floating_window.redo()
  local redo_msg = message.from_redo(message.insert_waypoint(1))
  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(7, state.waypoints[1].linenr)
  tu.assert_eq(1, state.wpi)
  tu.assert_eq(redo_msg, tu.get_last_message())
end)
