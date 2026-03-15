local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0

local config = require("waypoint.config")
local crud = require("waypoint.waypoint_crud")
local floating_window = require("waypoint.floating_window")
local message = require'waypoint.message'
local state = require("waypoint.state")
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local uw = require'waypoint.utils_waypoint'

local visible_extmark_text = config.mark_char .. " "
local invisible_extmark_text = "  "

-- TODO: finish
describe('Undo delete', function()
  assert(u.file_exists(file_0))
  tu.edit_file(file_0)
  crud.append_waypoint_wrapper()
  local bufnr = vim.fn.bufnr()
  local extmarks = uw.buf_get_extmarks(bufnr)

  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(1, #extmarks)
  tu.assert_eq(0, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)

  floating_window.open()
  floating_window.undo()
  extmarks = uw.buf_get_extmarks(bufnr)

  tu.assert_eq(0, #state.waypoints)
  tu.assert_eq(1, #extmarks)
  tu.assert_eq(0, extmarks[1][2])
  tu.assert_eq(invisible_extmark_text, extmarks[1][4].sign_text)

  floating_window.redo()
  extmarks = uw.buf_get_extmarks(bufnr)

  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(1, #extmarks)
  tu.assert_eq(0, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)

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
end)


-- one open buffer
-- close the buffer
-- delete the waypoint
-- undo the deletion
-- buffer should still be closed, but waypoint text should be there
-- go to waypoint
-- buffer should be opened
describe('Undo delete then jump', function()
end)

describe('Undo delete then jump', function()
end)
