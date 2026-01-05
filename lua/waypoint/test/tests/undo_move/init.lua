local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0

local crud = require("waypoint.waypoint_crud")
local floating_window = require("waypoint.floating_window")
local message = require'waypoint.message'
local state = require("waypoint.state")
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local uw = require'waypoint.utils_waypoint'

describe('Undo move', function()
  assert(u.file_exists(file_0))

  floating_window.open()
  floating_window.undo()
  floating_window.close()

  tu.assert_eq(message.at_earliest_change, tu.get_last_message())

  vim.cmd.edit({args = {file_0}, bang=true})
  tu.goto_line(7)
  crud.append_waypoint_wrapper()
  tu.goto_line(8)
  crud.append_waypoint_wrapper()
  tu.goto_line(12)
  crud.append_waypoint_wrapper()

  tu.assert_eq(3, #state.waypoints)
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[3]))

  floating_window.open()
  floating_window.move_waypoint_down()

  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[3]))

  local undo_msg
  undo_msg = message.from_undo(message.move_waypoint(2, 1))
  floating_window.undo()
  tu.assert_eq(undo_msg, tu.get_last_message())

  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[3]))

  local redo_msg
  redo_msg = message.from_redo(message.move_waypoint(1, 2))
  floating_window.redo()
  tu.assert_eq(redo_msg, tu.get_last_message())

  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[3]))

  floating_window.open()
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  floating_window.move_waypoint_up()
  floating_window.move_waypoint_up()

  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[3]))

  local redo_msg_1 = message.move_waypoint(3, 2)
  local redo_msg_2 = message.move_waypoint(2, 1)
  local undo_msg_1 = message.move_waypoint(2, 3)
  local undo_msg_2 = message.move_waypoint(1, 2)

  tu.assert_eq(redo_msg_2, tu.get_last_message())

  floating_window.redo()
  tu.assert_eq(message.at_latest_change, tu.get_last_message())

  floating_window.undo()
  tu.assert_eq(message.from_undo(undo_msg_2), tu.get_last_message())

  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[3]))

  floating_window.undo()
  tu.assert_eq(message.from_undo(undo_msg_1), tu.get_last_message())

  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[3]))

  floating_window.redo()
  tu.assert_eq(message.from_redo(redo_msg_1), tu.get_last_message())

  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[3]))

  floating_window.redo()
  tu.assert_eq(message.from_redo(redo_msg_2), tu.get_last_message())

  tu.assert_eq(12, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq( 8, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq( 7, uw.linenr_from_waypoint(state.waypoints[3]))

  floating_window.redo()
  tu.assert_eq(message.at_latest_change, tu.get_last_message())
end)
