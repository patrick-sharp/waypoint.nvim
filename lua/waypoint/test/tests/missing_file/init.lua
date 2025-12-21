local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_1 = test_list.file_1

local file = require'waypoint.file'
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local constants = require("waypoint.constants")
local tu = require'waypoint.test.util'

describe('Missing file', function()
  file.load_from_file("lua/waypoint/test/tests/missing_file/waypoints.json")
  assert(#state.waypoints == 3)

  floating_window.open()

  local lines

  local has_file_dne = function(str)
    return string.sub(str, 1, #constants.file_dne_error) == constants.file_dne_error
  end

  lines = tu.get_waypoint_buffer_lines()
  assert(lines[1][3] == "1")
  assert(not has_file_dne(lines[1][4]))
  assert(lines[2][3] == "8")
  assert(has_file_dne(lines[2][4]))
  assert(lines[3][3] == "9")
  assert(has_file_dne(lines[3][4]))

  local nonexistent_file = "./lua/waypoint/test/tests/common/does_not_exist.lua"

  floating_window.move_waypoints_to_file(nonexistent_file, file_1)

  return true
end)
