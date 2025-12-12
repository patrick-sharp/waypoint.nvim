local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local file = require'waypoint.file'
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")

describe('Missing file', function()
  file.load_from_file("lua/waypoint/test/tests/missing_file/waypoints.json")
  assert(#state.waypoints == 3)

  floating_window.open()

  return true
end)
