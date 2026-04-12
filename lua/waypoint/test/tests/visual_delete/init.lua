local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local message = require'waypoint.message'
local u = require("waypoint.util")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'

describe('Visual delete', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_delete/waypoints.json"
  local num_waypoints = 6
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  local waypoints = vim.deepcopy(state.waypoints)

  floating_window.open()

  local lines
  local num_deleted = 0

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(num_waypoints, u.len(lines))

  -- delete one waypoint
  tu.enter_visual_mode()
  floating_window.delete()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  num_deleted = 1
  tu.assert_eq(num_waypoints - num_deleted, u.len(lines))
  tu.assert_eq(num_waypoints - num_deleted, #state.waypoints)
  tu.assert_eq(false, u.is_in_visual_mode())
  tu.assert_eq(1, state.wpi)

  for i = 1, num_waypoints - 1 do
    tu.assert_waypoints_eq(waypoints[i+1], state.waypoints[i])
  end

  -- delete two waypoints
  tu.enter_visual_mode()
  floating_window.next_waypoint()
  floating_window.delete()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  num_deleted = num_deleted + 2
  tu.assert_eq(num_waypoints - num_deleted, u.len(lines))
  tu.assert_eq(num_waypoints - num_deleted, #state.waypoints)
  for i = 1, num_waypoints - num_deleted do
    tu.assert_waypoints_eq(waypoints[i+3], state.waypoints[i])
  end

  -- delete remaining waypoints
  tu.enter_visual_mode()
  floating_window.move_to_last_waypoint()
  floating_window.delete()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(1, u.len(lines)) -- every buffer has at least one line
  tu.assert_eq(nil, state.wpi)
  tu.assert_eq(0, #state.waypoints)
end)

describe('Visual delete undo', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_delete/waypoints.json"
  local num_waypoints = 6
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  local waypoints = vim.deepcopy(state.waypoints)

  floating_window.open()

  local lines
  local num_deleted = 0

  lines = tu.get_waypoint_buffer_lines_trimmed()
  tu.assert_eq(num_waypoints, u.len(lines))

  -- delete two waypoints
  tu.enter_visual_mode()
  floating_window.next_waypoint()
  floating_window.delete()
  lines = tu.get_waypoint_buffer_lines_trimmed()
  num_deleted = num_deleted + 2
  tu.assert_eq(num_waypoints - num_deleted, u.len(lines))
  tu.assert_eq(num_waypoints - num_deleted, #state.waypoints)
  for i = 1, num_waypoints - num_deleted do
    tu.assert_waypoints_eq(waypoints[i+num_deleted], state.waypoints[i])
  end

  floating_window.close()

  -- delete lines those waypoints were on
  tu.edit_file(file_0)
  tu.normal('dd')
  tu.normal('dd')

  floating_window.open()
  floating_window.undo()

  local msg = tu.get_last_message()

  assert(msg)
  tu.assert_string_contains(msg, 2 .. message.not_shown_suffix)
end)

describe('Visual delete with undrawn', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_delete/waypoints.json"
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  local waypoints = vim.deepcopy(state.waypoints)

  -- delete lines for waypoints 2 and 3
  tu.edit_file(file_0)
  u.goto_line(3)
  tu.normal('dd')
  u.goto_line(2)
  tu.normal('dd')

  floating_window.open()

  -- delete two waypoints
  tu.enter_visual_mode()
  floating_window.next_waypoint()
  floating_window.delete()

  tu.assert_eq(#waypoints - 2, #state.waypoints)
  tu.assert_waypoints_eq(waypoints[2], state.waypoints[1])
  tu.assert_waypoints_eq(waypoints[3], state.waypoints[2])
  tu.assert_waypoints_eq(waypoints[5], state.waypoints[3])

  local redo_msg = message.deleted_waypoints .. "1-2"
  local undo_msg = message.restored_waypoints .. "1-2"

  floating_window.open()
  floating_window.undo()

  local msg

  msg = tu.get_last_message()
  assert(msg)
  tu.assert_string_contains(msg, undo_msg)

  floating_window.redo()

  msg = tu.get_last_message()
  assert(msg)
  tu.assert_string_contains(msg, redo_msg)
end)
