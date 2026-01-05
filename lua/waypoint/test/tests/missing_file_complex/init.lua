local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_1 = test_list.file_1

local file = require'waypoint.file'
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local constants = require("waypoint.constants")
local message = require("waypoint.message")
local tu = require'waypoint.test.util'
local uw = require'waypoint.utils_waypoint'

-- This test is more complex than the basic missing_file, as it involves the text of the waypoints being slightly different from the text in the file.
-- This causes the locate_waypoints_in_file function to use a levenshtein search
describe('Missing file complex', function()
  file.load_from_file("lua/waypoint/test/tests/missing_file_complex/waypoints.json")
  tu.assert_eq(2, #state.waypoints)

  floating_window.open()

  local lines

  local has_file_dne = function(str)
    return string.sub(str, 1, #constants.file_dne_error) == constants.file_dne_error
  end

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq("8", lines[1][3])
  tu.assert_eq(true, has_file_dne(lines[1][4]))
  tu.assert_eq("9", lines[2][3])
  tu.assert_eq(true, has_file_dne(lines[2][4]))

  local nonexistent_file = "lua/waypoint/test/tests/common/does_not_exist.lua"

  local result
  local msg

  result = floating_window.move_waypoints_to_file(nonexistent_file, file_1)
  msg = tu.get_last_message()
  assert(result)
  tu.assert_eq(msg, message.moved_waypoints_to_file(2, nonexistent_file, file_1))

  local file_1_bufnr = vim.fn.bufnr(file_1)
  tu.assert_neq(-1, file_1_bufnr)

  tu.assert_eq(file_1, state.waypoints[1].filepath)
  tu.assert_eq(14, uw.linenr_from_waypoint(state.waypoints[1]))
  tu.assert_eq(file_1_bufnr, state.waypoints[1].bufnr)

  tu.assert_eq(file_1, state.waypoints[2].filepath)
  tu.assert_eq(18, uw.linenr_from_waypoint(state.waypoints[2]))
  tu.assert_eq(file_1_bufnr, state.waypoints[2].bufnr)

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(file_1, lines[1][2])
  tu.assert_eq("14", lines[1][3])
  tu.assert_eq("table.insert(results, \"hello\")", lines[1][4])

  tu.assert_eq(file_1, lines[2][2])
  tu.assert_eq("18", lines[2][3])
  tu.assert_eq("table.insert(results, \"world\")", lines[2][4])
end)
