local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local crud = require("waypoint.waypoint_crud")
local state = require("waypoint.state")
local u = require("waypoint.util")
local tu = require'waypoint.test.util'
local uw = require'waypoint.utils_waypoint'

describe('Buffer callbacks', function()
  assert(u.file_exists(file_0))

  vim.cmd.edit({args = {file_0}, bang=true})
  u.goto_line(7)
  crud.append_waypoint_wrapper()
  u.goto_line(8)
  crud.append_waypoint_wrapper()

  vim.cmd.edit({args = {file_1}, bang=true})
  u.goto_line(11)
  crud.append_waypoint_wrapper()

  tu.assert_eq(3, #state.waypoints)
  tu.assert_eq(7,       uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq(file_0,  u.path_from_buf(state.waypoints[1].bufnr))
  tu.assert_eq(8,       uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq(file_0,  u.path_from_buf(state.waypoints[2].bufnr))
  tu.assert_eq(11,      uw.linenr_from_waypoint(state.waypoints[3]))
  tu.assert_eq(file_1,  u.path_from_buf(state.waypoints[3].bufnr))

  vim.api.nvim_buf_delete(vim.fn.bufnr(file_0), { force = true })

  -- assert waypoints are in a bufferless state
  tu.assert_eq(false, state.waypoints[1].has_buffer)
  tu.assert_eq(nil, state.waypoints[1].extmark_id)
  tu.assert_eq(nil, state.waypoints[1].bufnr)
  tu.assert_neq(nil, state.waypoints[1].filepath)
  tu.assert_neq(nil, state.waypoints[1].linenr)
  tu.assert_neq(nil, state.waypoints[1].text)
  tu.assert_eq(false, state.waypoints[2].has_buffer)
  tu.assert_eq(nil, state.waypoints[2].extmark_id)
  tu.assert_eq(nil, state.waypoints[2].bufnr)
  tu.assert_neq(nil, state.waypoints[2].filepath)
  tu.assert_neq(nil, state.waypoints[2].linenr)
  tu.assert_neq(nil, state.waypoints[2].text)
  tu.assert_eq(true, state.waypoints[3].has_buffer)
  tu.assert_neq(nil, state.waypoints[3].extmark_id)
  tu.assert_neq(nil, state.waypoints[3].bufnr)
  tu.assert_eq(nil, state.waypoints[3].filepath)
  tu.assert_eq(nil, state.waypoints[3].linenr)
  tu.assert_eq(nil, state.waypoints[3].text)

  vim.cmd.edit({args = {file_0}, bang=true})

  -- assert waypoints are in restored state
  tu.assert_eq(true, state.waypoints[1].has_buffer)
  tu.assert_neq(nil, state.waypoints[1].extmark_id)
  tu.assert_neq(nil, state.waypoints[1].bufnr)
  tu.assert_eq(nil, state.waypoints[1].filepath)
  tu.assert_eq(nil, state.waypoints[1].linenr)
  tu.assert_eq(nil, state.waypoints[1].text)
  tu.assert_eq(true, state.waypoints[2].has_buffer)
  tu.assert_neq(nil, state.waypoints[2].extmark_id)
  tu.assert_neq(nil, state.waypoints[2].bufnr)
  tu.assert_eq(nil, state.waypoints[2].filepath)
  tu.assert_eq(nil, state.waypoints[2].linenr)
  tu.assert_eq(nil, state.waypoints[2].text)
  tu.assert_eq(true, state.waypoints[3].has_buffer)
  tu.assert_neq(nil, state.waypoints[3].extmark_id)
  tu.assert_neq(nil, state.waypoints[3].bufnr)
  tu.assert_eq(nil, state.waypoints[3].filepath)
  tu.assert_eq(nil, state.waypoints[3].linenr)
  tu.assert_eq(nil, state.waypoints[3].text)
end)
