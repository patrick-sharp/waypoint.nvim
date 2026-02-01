local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'

describe('Visual reselect', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_reselect/waypoints.json"
  assert(u.file_exists(waypoints_json))

  local col_a = 4
  local col_b = 8

  file.load_from_file(waypoints_json)

  floating_window.open()

  -- All these are for 0 context (A, B, and C):

  -- reselect one line at the beginning
  u.enter_visual_mode()
  u.goto_char_col(col_a)
  u.switch_visual()
  u.goto_char_col(col_b)
  floating_window.draw_waypoint_window() -- have to put this in here to give the waypoint window a chance to save the visual position
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(1, col_b, 1, col_a)
  u.exit_visual_mode()

  -- reselect two lines at the beginning
  u.enter_visual_mode()
  u.goto_char_col(col_a)
  u.switch_visual()
  u.goto_char_col(col_b)
  floating_window.next_waypoint()
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(2, col_b, 1, col_a)
  u.exit_visual_mode()

  -- reselect one line in the middle
  -- reselect two lines in the middle
  -- reselect all waypoints


  -- All these are for starting at 0 context, then increasing, then reselecting.
  -- reselect one line at the beginning
  -- reselect two lines at the beginning
  -- reselect one line in the middle
  -- reselect two lines in the middle
  -- reselect all waypoints

  -- All these are for starting at 5 context, then increasing, then reselecting.
  -- reselect one line at the beginning
  -- reselect two lines at the beginning
  -- reselect one line in the middle
  -- reselect two lines in the middle
  -- reselect all waypoints
end)
