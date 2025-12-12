local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local crud = require("waypoint.waypoint_crud")
local u = require("waypoint.utils")

describe('Sort', function()
  u.assert_file_exists(file_0)
  u.assert_file_exists(file_1)

  assert(state.sort_by_file_and_line == false)

  vim.cmd.edit({args = {file_0}, bang=true})
  vim.cmd.normal({args = {"7G"}, bang=true})
  crud.toggle_waypoint()
  vim.cmd.edit({args = {file_1}, bang=true})
  vim.cmd.normal({args = {"8G"}, bang=true})
  crud.toggle_waypoint()
  vim.cmd.normal({args = {"5G"}, bang=true})
  crud.toggle_waypoint()
  vim.cmd.edit({args = {file_0}, bang=true})
  vim.cmd.normal({args = {"3G"}, bang=true})
  crud.toggle_waypoint()
  vim.cmd.normal({args = {"17G"}, bang=true})
  crud.toggle_waypoint()

  floating_window.open()

  assert(#state.waypoints == 5)
  assert(#state.sorted_waypoints == 5)
  assert(state.waypoints[1].filepath == file_0)
  assert(state.waypoints[2].filepath == file_1)
  assert(state.waypoints[3].filepath == file_1)
  assert(state.waypoints[4].filepath == file_0)
  assert(state.waypoints[5].filepath == file_0)

  assert(state.waypoints[1].linenr ==  7)
  assert(state.waypoints[2].linenr ==  8)
  assert(state.waypoints[3].linenr ==  5)
  assert(state.waypoints[4].linenr ==  3)
  assert(state.waypoints[5].linenr == 17)

  local assert_waypoint_locations = function()
    assert(state.sorted_waypoints[1].filepath == file_0)
    assert(state.sorted_waypoints[2].filepath == file_0)
    assert(state.sorted_waypoints[3].filepath == file_0)
    assert(state.sorted_waypoints[4].filepath == file_1)
    assert(state.sorted_waypoints[5].filepath == file_1)

    assert(state.sorted_waypoints[1].linenr ==  3)
    assert(state.sorted_waypoints[2].linenr ==  7)
    assert(state.sorted_waypoints[3].linenr == 17)
    assert(state.sorted_waypoints[4].linenr ==  5)
    assert(state.sorted_waypoints[5].linenr ==  8)
  end

  assert_waypoint_locations()

  floating_window.toggle_full_path()

  local lines
  local bufnr = vim.fn.bufnr()
  local pattern = ' ' .. constants.table_separator .. ' '

  lines = vim.api.nvim_buf_get_lines(bufnr, 0, 5, true)
  assert(u.split(lines[1], pattern)[2] == file_0)
  assert(u.split(lines[2], pattern)[2] == file_1)
  assert(u.split(lines[3], pattern)[2] == file_1)
  assert(u.split(lines[4], pattern)[2] == file_0)
  assert(u.split(lines[5], pattern)[2] == file_0)

  floating_window.toggle_sort()

  assert(state.sort_by_file_and_line == true)
  assert(#state.waypoints == 5)
  assert(#state.sorted_waypoints == 5)

  assert_waypoint_locations()

  lines = vim.api.nvim_buf_get_lines(bufnr, 0, 5, true)
  assert(u.split(lines[1], pattern)[2] == file_0)
  assert(u.split(lines[2], pattern)[2] == file_0)
  assert(u.split(lines[3], pattern)[2] == file_0)
  assert(u.split(lines[4], pattern)[2] == file_1)
  assert(u.split(lines[5], pattern)[2] == file_1)
end)
