local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local crud = require("waypoint.waypoint_crud")
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local uw = require'waypoint.utils_waypoint'

describe('Sort', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))

  assert(state.sort_by_file_and_line == false)

  vim.cmd.edit({args = {file_0}, bang=true})
  u.goto_line(7)
  crud.append_waypoint_wrapper()
  vim.cmd.edit({args = {file_1}, bang=true})
  u.goto_line(8)
  crud.append_waypoint_wrapper()
  u.goto_line(5)
  crud.append_waypoint_wrapper()
  vim.cmd.edit({args = {file_0}, bang=true})
  u.goto_line(3)
  crud.append_waypoint_wrapper()
  u.goto_line(17)
  crud.append_waypoint_wrapper()

  floating_window.open()

  assert(#state.waypoints == 5)
  assert(#state.sorted_waypoints == 5)
  assert(state.waypoints[1].filepath == file_0)
  assert(state.waypoints[2].filepath == file_1)
  assert(state.waypoints[3].filepath == file_1)
  assert(state.waypoints[4].filepath == file_0)
  assert(state.waypoints[5].filepath == file_0)

  assert(uw.linenr_from_waypoint(state.waypoints[1]) ==  7)
  assert(uw.linenr_from_waypoint(state.waypoints[2]) ==  8)
  assert(uw.linenr_from_waypoint(state.waypoints[3]) ==  5)
  assert(uw.linenr_from_waypoint(state.waypoints[4]) ==  3)
  assert(uw.linenr_from_waypoint(state.waypoints[5]) == 17)

  local assert_waypoint_locations = function()
    assert(state.sorted_waypoints[1].filepath == file_0)
    assert(state.sorted_waypoints[2].filepath == file_0)
    assert(state.sorted_waypoints[3].filepath == file_0)
    assert(state.sorted_waypoints[4].filepath == file_1)
    assert(state.sorted_waypoints[5].filepath == file_1)

    assert(uw.linenr_from_waypoint(state.sorted_waypoints[1]) ==  3)
    assert(uw.linenr_from_waypoint(state.sorted_waypoints[2]) ==  7)
    assert(uw.linenr_from_waypoint(state.sorted_waypoints[3]) == 17)
    assert(uw.linenr_from_waypoint(state.sorted_waypoints[4]) ==  5)
    assert(uw.linenr_from_waypoint(state.sorted_waypoints[5]) ==  8)
  end

  assert_waypoint_locations()

  floating_window.toggle_full_path()

  local lines

  lines = tu.get_waypoint_buffer_lines_trimmed()

  assert(lines[1][2] == file_0)
  assert(lines[2][2] == file_1)
  assert(lines[3][2] == file_1)
  assert(lines[4][2] == file_0)
  assert(lines[5][2] == file_0)

  floating_window.toggle_sort()

  assert(state.sort_by_file_and_line == true)
  assert(#state.waypoints == 5)
  assert(#state.sorted_waypoints == 5)

  assert_waypoint_locations()

  lines = tu.get_waypoint_buffer_lines_trimmed()
  assert(lines[1][2] == file_0)
  assert(lines[2][2] == file_0)
  assert(lines[3][2] == file_0)
  assert(lines[4][2] == file_1)
  assert(lines[5][2] == file_1)
end)
