local describe = require('waypoint.test.test_list').describe
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local crud = require("waypoint.waypoint_crud")
local u = require("waypoint.utils")

describe('Sort', function()
  local file_0 = "lua/waypoint/test/tests/sort/file_0.lua"
  local file_1 = "lua/waypoint/test/tests/sort/file_1.lua"

  u.assert_exists(file_0)
  u.assert_exists(file_1)

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

  assert(#state.waypoints == 5)
  assert(#state.sorted_waypoints == 5)
  -- assert(state.waypoints[1].linenr == 7)

  floating_window.toggle_sort()
  assert(state.sort_by_file_and_line == true)

  assert(#state.waypoints == 5)
  assert(#state.sorted_waypoints == 5)

  return true
end)
