local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'
local uw = require'waypoint.utils_waypoint'

local waypoints_json = "lua/waypoint/test/tests/highlight_treesitter/waypoints.json"

describe('Highlight treesitter', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  -- TODO: finish

end)
