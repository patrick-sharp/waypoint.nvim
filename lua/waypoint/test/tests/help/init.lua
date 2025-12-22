local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local floating_window = require("waypoint.floating_window")
local config = require("waypoint.config")
local u = require("waypoint.utils")

describe('Help', function()
  assert(u.len(config.keybindings.global_keybindings) == #floating_window.global_keybindings_description)
  assert(u.len(config.keybindings.waypoint_window_keybindings) == #floating_window.waypoint_window_keybindings_description)
  assert(u.len(config.keybindings.help_keybindings) == #floating_window.help_keybindings_description)
end)
