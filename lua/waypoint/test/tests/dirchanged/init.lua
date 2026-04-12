local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json
local wp_1_text = test_list.wp_1_text
local wp_2_text = test_list.wp_2_text
local wp_3_text = test_list.wp_3_text

local other_wp_1_text = "function M.fn_0()"
local other_wp_2_text = "function M.fn_0()"
local other_wp_3_text = "function M.fn_1()"

local dir_old = vim.fn.getcwd()
local dir_new = "lua/waypoint/test/tests/dirchanged/"

local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local file = require'waypoint.file'
local u = require("waypoint.util")
local tu = require'waypoint.test.util'

describe('DirChanged', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))
  file.load_from_file(waypoints_json)

  floating_window.open()

  local lines

  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_1_text, lines[1][4])
  tu.assert_eq(wp_2_text, lines[2][4])
  tu.assert_eq(wp_3_text, lines[3][4])

  floating_window.close()
  vim.api.nvim_set_current_dir(dir_new)
  floating_window.open()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(other_wp_1_text, lines[1][4])
  tu.assert_eq(other_wp_2_text, lines[2][4])
  tu.assert_eq(other_wp_3_text, lines[3][4])

  floating_window.close()
  vim.api.nvim_set_current_dir(dir_old)
  floating_window.open()
  lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(wp_1_text, lines[1][4])
  tu.assert_eq(wp_2_text, lines[2][4])
  tu.assert_eq(wp_3_text, lines[3][4])
end)
