local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.util")
local tu = require'waypoint.test.util'

describe('Bad load invalid waypoints', function()
  local waypoints_json = "lua/waypoint/test/tests/bad_load/invalid_waypoints.json"
  assert(u.file_exists(waypoints_json))
  file.load_from_file(waypoints_json)
  floating_window.open()
  local lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq("Expected value of type string for key filepath, but received nil.", lines[1][4])
  assert(string.find(lines[2][4], "does not exist") ~= nil)
end)


describe('Bad load invalid file', function()
  local waypoints_json = "lua/waypoint/test/tests/bad_load/invalid_file.json"
  assert(u.file_exists(waypoints_json))
  file.load_from_file(waypoints_json)
  floating_window.open()
  local lines = tu.get_waypoint_buffer_lines_trimmed()
  assert(string.find(lines[1][1], "Error loading waypoints from file") ~= nil)
end)
