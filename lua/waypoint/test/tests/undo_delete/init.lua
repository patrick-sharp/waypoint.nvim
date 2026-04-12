local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0

local config = require("waypoint.config")
local crud = require("waypoint.waypoint_crud")
local floating_window = require("waypoint.floating_window")
local message = require'waypoint.message'
local state = require("waypoint.state")
local u = require("waypoint.util")
local tu = require'waypoint.test.util'
local uw = require'waypoint.utils_waypoint'

local visible_extmark_text = config.mark_char .. " "
local invisible_extmark_text = "  "

-- one open buffer
-- one waypoint
-- delete the waypoint
-- open waypoint window and undo the delete
-- redo the delete
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
end)

-- one open buffer
-- one waypoint
-- close the buffer
-- delete the waypoint
-- undo the deletion
-- buffer should still be closed, but waypoint should be there
-- should show "no open buffer for file"
-- open file
-- should return to normal
describe('Undo delete before reopen', function()
  assert(u.file_exists(file_0))
  tu.edit_file(file_0)
  crud.append_waypoint_wrapper()

  assert(state.waypoints[1].has_buffer)

  vim.api.nvim_buf_delete(vim.fn.bufnr(file_0), { force = true })

  tu.assert_eq(1, #state.waypoints)
  assert(not state.waypoints[1].has_buffer)

  floating_window.open()
  floating_window.delete()

  tu.assert_eq(0, #state.waypoints)

  floating_window.undo()

  tu.assert_eq(1, #state.waypoints)
  assert(not state.waypoints[1].has_buffer)

  local lines
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(message.no_open_buffer_for_file, lines[1][4])

  floating_window.close()
  tu.edit_file(file_0)

  tu.assert_eq(1, #state.waypoints)
  assert(state.waypoints[1].has_buffer)

  local extmarks = uw.buf_get_extmarks(vim.fn.bufnr(file_0))
  tu.assert_eq(1, #extmarks)
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
end)

describe('Undo delete after reopen', function()
  assert(u.file_exists(file_0))
  tu.edit_file(file_0)
  crud.append_waypoint_wrapper()

  assert(state.waypoints[1].has_buffer)

  tu.assert_eq(1, #state.waypoints)
  assert(state.waypoints[1].has_buffer)

  floating_window.open()
  floating_window.delete()

  tu.assert_eq(0, #state.waypoints)

  vim.api.nvim_buf_delete(vim.fn.bufnr(file_0), { force = true })

  tu.assert_eq(0, #state.waypoints)

  floating_window.close()
  tu.edit_file(file_0)
  floating_window.open()
  floating_window.undo()
  floating_window.close()

  tu.assert_eq(1, #state.waypoints)

  local extmarks = uw.buf_get_extmarks(vim.fn.bufnr(file_0))
  tu.assert_eq(1, #state.waypoints)
  assert(state.waypoints[1].has_buffer)

  tu.assert_eq(1, #extmarks)
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
end)

-- one open buffer
-- one waypoint
-- delete the waypoint
-- delete the line the waypoint was on in the buffer
-- undo the deletion in the waypoint window
-- waypoint should not appear (should be message in notify box)
describe('Undo undrawn waypoint', function()
  tu.edit_file(file_0)
  crud.append_waypoint_wrapper()

  floating_window.open()
  floating_window.delete()
  floating_window.close()

  tu.edit_file(file_0)
  tu.normal('dd')

  floating_window.open()
  floating_window.undo()

  tu.assert_eq(1, #state.waypoints)
  assert(not uw.should_draw_waypoint(state.waypoints[1]))

  local msg

  msg = tu.get_last_message()

  assert(msg)
  tu.assert_string_contains(msg, message.restored_waypoint .. 1)
  tu.assert_string_contains(msg, 1 .. message.not_shown_suffix)

  floating_window.redo()

  msg = tu.get_last_message()

  assert(msg)
  tu.assert_string_contains(msg, message.deleted_waypoint .. 1)
end)
