local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local crud = require("waypoint.waypoint_crud")
local state = require("waypoint.state")
local filter = require("waypoint.filter")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local tu = require'waypoint.test.util'

local before = "lua/waypoint/test/tests/filter/before.lua"
local after = "lua/waypoint/test/tests/filter/after.lua"

-- this test simulates a filter by doing the following:
-- 1. call the filter.save_file_contents callback I attach to the FilterWritePre autocmd event
-- 2. delete the contents of the buffer
-- 3. paste the contents of the "filtered" text (actually precomputed) into the buffer
-- 4. call the filter.fix_waypoint_positions callback I attach to the FilterWritePost autocmd event

describe('Filter', function()
  assert(u.file_exists(before))
  assert(u.file_exists(after))

  vim.cmd.edit({args = {before}, bang=true})
  local before_bufnr = vim.fn.bufnr(before)
  local before_lines = vim.api.nvim_buf_get_lines(before_bufnr, 0, -1, false)

  vim.cmd.edit({args = {after}, bang=true})
  local after_bufnr = vim.fn.bufnr(after)
  local after_lines = vim.api.nvim_buf_get_lines(after_bufnr, 0, -1, false)

  local test_bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, true, before_lines)

  vim.cmd.buffer(test_bufnr)

  -- make sure we aren't accidentally making it easy to override our test files by editing one of them
  tu.assert_neq(before_bufnr, vim.fn.bufnr())
  tu.assert_neq(after_bufnr, vim.fn.bufnr())

  -- place a waypoint on a line that will have whitespace removed
  u.goto_line(1)
  crud.append_waypoint_wrapper()

  -- place a waypoint on a line that will not be moved or changed
  u.goto_line(2)
  crud.append_waypoint_wrapper()

  -- place a waypoint in the middle of the long line that gets split
  u.goto_line(3)
  crud.append_waypoint_wrapper()

  -- place a waypoint on a line that will be moved, but not have its text altered
  -- lines that get concatenated
  u.goto_line(5)
  crud.append_waypoint_wrapper()

  -- place a waypoint in one of the lines in the middle of the group of short
  -- lines that get concatenated
  u.goto_line(9)
  crud.append_waypoint_wrapper()

  -- pre-filter callback
  filter.save_file_contents()
  -- delete lines in buffer (except the last one)
  vim.api.nvim_buf_set_lines(test_bufnr, 0, #before_lines-1, true, {})
  -- replace with "filtered" content
  vim.api.nvim_buf_set_lines(test_bufnr, 1, -1, true, after_lines)
  -- delete the one line we left from the original file, extmarks will now move to new lines
  vim.api.nvim_buf_set_lines(test_bufnr, 0, 1, true, {})

  tu.assert_eq(#after_lines, vim.api.nvim_buf_line_count(test_bufnr))

  -- post filter callback
  filter.fix_waypoint_positions()

  tu.assert_eq(1, uw.linenr_from_waypoint(state.waypoints[1])) -- should still be on same line
  tu.assert_eq(2, uw.linenr_from_waypoint(state.waypoints[2])) -- should still be on same line
  tu.assert_eq(3, uw.linenr_from_waypoint(state.waypoints[3])) -- should still be on same line
  tu.assert_eq(7, uw.linenr_from_waypoint(state.waypoints[4])) -- should have been moved down by the wide table getting split into multiple lines
  tu.assert_eq(8, uw.linenr_from_waypoint(state.waypoints[5])) -- should have been moved up by the tall table getting concatenated to one line
end)
