local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

describe('Navigation basic', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)
  floating_window.open()

  local lines
  local linenr
  local cursor_linenr

  lines = tu.get_waypoint_buffer_lines_trimmed()

  floating_window.move_to_last_waypoint()
  floating_window.go_to_current_waypoint()

  linenr = tonumber(lines[#lines][3])
  tu.assert_eq("number", type(linenr))
  tu.assert_eq(false, floating_window.is_open())
  cursor_linenr = vim.api.nvim_win_get_cursor(0)[1]
  tu.assert_eq(linenr, cursor_linenr)

  floating_window.open()
  floating_window.prev_waypoint()
  floating_window.go_to_current_waypoint()

  linenr = tonumber(lines[#lines - 1][3])
  tu.assert_eq("number", type(linenr))
  tu.assert_eq(false, floating_window.is_open())
  cursor_linenr = vim.api.nvim_win_get_cursor(0)[1]
  tu.assert_eq(linenr, cursor_linenr)

  floating_window.open()
  floating_window.next_waypoint()
  floating_window.move_to_first_waypoint()
  floating_window.go_to_current_waypoint()

  linenr = tonumber(lines[1][3])
  tu.assert_eq("number", type(linenr))
  tu.assert_eq(false, floating_window.is_open())
  cursor_linenr = vim.api.nvim_win_get_cursor(0)[1]
  tu.assert_eq(linenr, cursor_linenr)
end)
