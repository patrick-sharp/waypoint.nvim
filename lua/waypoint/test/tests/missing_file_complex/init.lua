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

-- This test is more complex than the basic missing_file, as it involves the text of the waypoints being slightly different from the text in the file.
-- This causes the locate_waypoints_in_file function to use a levenshtein search
describe('Missing file complex', function()
  file.load_from_file("lua/waypoint/test/tests/missing_file_complex/waypoints.json")
  assert(#state.waypoints == 3)

  floating_window.open()

  local lines

  local has_file_dne = function(str)
    return string.sub(str, 1, #constants.file_dne_error) == constants.file_dne_error
  end

  lines = tu.get_waypoint_buffer_lines()
  assert(lines[1][3] == "8")
  assert(not has_file_dne(lines[1][4]))
  assert(lines[2][3] == "9")
  assert(has_file_dne(lines[2][4]))

  local nonexistent_file = "lua/waypoint/test/tests/common/does_not_exist.lua"

  local result
  local msg

  result = floating_window.move_waypoints_to_file(nonexistent_file, file_1)
  msg = tu.get_last_message()
  assert(result)
  tu.assert_eq(msg, message.moved_waypoints_to_file(2, nonexistent_file, file_1))

  lines = tu.get_waypoint_buffer_lines()
  assert(lines[1][2] == file_1)
  assert(lines[1][3] == "14")
  assert(lines[1][4] == "table.insert(results, \"hello\")")

  assert(lines[2][2] == file_1)
  assert(lines[2][3] == "18")
  assert(lines[2][4] == "table.insert(results, \"world\")")
end)
