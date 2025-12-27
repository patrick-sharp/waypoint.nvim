local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local floating_window = require("waypoint.floating_window")
local config = require("waypoint.config")
local tu = require("waypoint.test.util")
local u = require("waypoint.utils")

describe('Help', function()
  tu.assert_eq(u.len(config.keybindings.global_keybindings),          #floating_window.global_keybindings_description)
  tu.assert_eq(u.len(config.keybindings.waypoint_window_keybindings), #floating_window.waypoint_window_keybindings_description)
  tu.assert_eq(u.len(config.keybindings.help_keybindings),            #floating_window.help_keybindings_description)
end)
