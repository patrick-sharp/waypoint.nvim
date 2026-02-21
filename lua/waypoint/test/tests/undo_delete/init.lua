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

-- TODO: finish
describe('Undo delete', function()
  -- one open buffer
  -- delete the waypoint
  -- undo
  -- it should be back

  -- one open buffer
  -- close the buffer
  -- delete the waypoint
  -- undo the deletion
  -- buffer should still be closed, but waypoint text should be there
  -- go to waypoint
  -- buffer should be opened

  -- one open buffer
  -- close the buffer
  -- delete the waypoint
  -- undo the deletion
  -- buffer should still be closed, but waypoint text should be there
  -- CHANGE THE BUFFER
  -- go to waypoint
  -- waypoint should be relocated in file similar to move_waypoints_to_file

  -- one open buffer
  -- close the buffer
  -- delete the waypoint
  -- undo the deletion
  -- buffer should still be closed, but waypoint text should be there
  -- CHANGE THE BUFFER TO DELETE THE LINE THE WAYPOINT IS ON
  -- go to waypoint
  -- waypoint should be drawn, but with error that it could not be found

  -- one open buffer
  -- delete the waypoint
  -- delete the line the waypoint was on in the buffer
  -- undo the deletion in the waypoint window
  -- waypoint should not appear (should be message in notify box)




  -- assert(u.file_exists(file_0))
  --
  -- floating_window.open()
  -- floating_window.undo()
  -- floating_window.close()
  --
  -- tu.assert_eq(message.at_earliest_change, tu.get_last_message())
  --
  -- floating_window.open()
  -- floating_window.redo()
  -- floating_window.close()
  --
  -- tu.assert_eq(message.at_latest_change, tu.get_last_message())
  --
  -- vim.cmd.edit({args = {file_0}, bang=true})
  -- u.goto_line(7)
  -- crud.insert_waypoint_wrapper()
  --
  -- tu.assert_eq(1, #state.waypoints)
  -- tu.assert_eq(7, uw.linenr_from_waypoint(state.waypoints[1]))
  --
  -- floating_window.open()
  -- floating_window.undo()
  -- local undo_msg = message.from_undo(message.remove_waypoint(1))
  -- tu.assert_eq(undo_msg, tu.get_last_message())
  -- tu.assert_eq(0, #state.waypoints)
  -- tu.assert_eq(nil, state.wpi)
  --
  -- floating_window.undo()
  -- tu.assert_eq(message.at_earliest_change, tu.get_last_message())
  --
  -- floating_window.redo()
  -- local redo_msg = message.from_redo(message.insert_waypoint(1))
  -- tu.assert_eq(1, #state.waypoints)
  -- tu.assert_eq(7, uw.linenr_from_waypoint(state.waypoints[1]))
  -- tu.assert_eq(1, state.wpi)
  -- tu.assert_eq(redo_msg, tu.get_last_message())
end)
