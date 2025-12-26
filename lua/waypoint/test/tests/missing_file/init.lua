local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local file = require'waypoint.file'
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local constants = require("waypoint.constants")
local message = require("waypoint.message")
local tu = require'waypoint.test.util'

describe('Missing file', function()
  file.load_from_file("lua/waypoint/test/tests/missing_file/waypoints.json")
  assert(#state.waypoints == 3)

  floating_window.open()

  local lines

  local has_file_dne = function(str)
    return string.sub(str, 1, #constants.file_dne_error) == constants.file_dne_error
  end

  lines = tu.get_waypoint_buffer_lines_trimmed()
  assert(lines[1][3] == "1")
  assert(not has_file_dne(lines[1][4]))
  assert(lines[2][3] == "8")
  assert(has_file_dne(lines[2][4]))
  assert(lines[3][3] == "9")
  assert(has_file_dne(lines[3][4]))

  local nonexistent_file = "lua/waypoint/test/tests/common/does_not_exist.lua"
  local nonexistent_file_other = "lua/waypoint/test/tests/common/does_not_exist_other.lua"

  local result
  local msg

  result = floating_window.move_waypoints_to_file(nonexistent_file, nonexistent_file)
  msg = tu.get_last_message()
  assert(not result)
  tu.assert_eq(msg, message.files_same(nonexistent_file))

  result = floating_window.move_waypoints_to_file(nonexistent_file, nonexistent_file_other)
  msg = tu.get_last_message()
  assert(not result)
  tu.assert_eq(msg, message.file_dne(nonexistent_file_other))

  result = floating_window.move_waypoints_to_file(nonexistent_file_other, nonexistent_file)
  msg = tu.get_last_message()
  assert(not result)
  tu.assert_eq(message.file_dne(nonexistent_file), msg)

  result = floating_window.move_waypoints_to_file(nonexistent_file_other, file_1)
  msg = tu.get_last_message()
  assert(not result)
  tu.assert_eq(message.no_waypoints_in_file(nonexistent_file_other), msg)

  result = floating_window.move_waypoints_to_file(nonexistent_file, file_1)
  msg = tu.get_last_message()
  tu.assert_eq(true, result)
  tu.assert_eq(message.moved_waypoints_to_file(2, nonexistent_file, file_1), msg)

  -- assert that we opened file_1 to put waypoints in it
  local file_1_bufnr = vim.fn.bufnr(file_1)
  tu.assert_neq(-1, file_1_bufnr)

  tu.assert_eq(file_1, state.waypoints[2].filepath)
  tu.assert_eq(8, state.waypoints[2].linenr)
  tu.assert_eq(file_1_bufnr, state.waypoints[2].bufnr)

  tu.assert_eq(file_1, state.waypoints[3].filepath)
  tu.assert_eq(9, state.waypoints[3].linenr)
  tu.assert_eq(file_1_bufnr, state.waypoints[3].bufnr)

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(file_0, lines[1][2])
  tu.assert_eq("local M = {}", lines[1][4])

  tu.assert_eq(file_1, lines[2][2])
  tu.assert_eq("table.insert(t, i)", lines[2][4])

  tu.assert_eq(file_1, lines[3][2])
  tu.assert_eq("end", lines[3][4])
end)
