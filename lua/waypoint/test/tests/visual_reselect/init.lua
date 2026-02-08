local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local state = require'waypoint.state'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

local num_waypoints = 6

local col_a = 4
local col_b = 8

local context_increase = 4
local before_context_increase = 3
local after_context_increase = 1

local function expand_context()
  for _=1,context_increase do
    floating_window.increase_context()
  end
  for _=1,before_context_increase do
    floating_window.increase_before_context()
  end
  for _=1,after_context_increase do
    floating_window.increase_after_context()
  end
end

---@param line_a integer
---@param line_b integer
local function adjust_expand_lines(line_a, line_b)
  local total_before_context = context_increase + before_context_increase
  local total_context = total_before_context + 1 + context_increase + after_context_increase
  local adjusted_line_a = (total_context + 1) * (line_a - 1) + total_before_context + 1
  local adjusted_line_b = (total_context + 1) * (line_b - 1) + total_before_context + 1
  return adjusted_line_a, adjusted_line_b
end

---@param test_type nil | "reselect_after_shrink" | "reselect_after_expand"
local function reselect_beginning_line(test_type)
  local line_a = 1
  local line_b = 1

  if test_type == "reselect_after_shrink" then
    expand_context()
  elseif test_type == "reselect_after_expand" then
    line_a, line_b = adjust_expand_lines(line_a, line_b)
  end
  u.enter_visual_mode()
  u.goto_char_col(col_a)
  u.switch_visual()
  u.goto_char_col(col_b)
  floating_window.draw_waypoint_window() -- have to put this in here to give the waypoint window a chance to save the visual position
  u.exit_visual_mode()
  u.goto_char_col(1)
  if test_type == "reselect_after_shrink" then
    floating_window.reset_context()
  elseif test_type == "reselect_after_expand" then
    expand_context()
  end
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(line_b, col_b, line_a, col_a)
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.move_to_first_waypoint()
  floating_window.reset_context()
end

---@param test_type nil | "reselect_after_shrink" | "reselect_after_expand"
local function reselect_beginning_two_lines(test_type)
  local line_a = 1
  local line_b = 2

  if test_type == "reselect_after_shrink" then
    expand_context()
  elseif test_type == "reselect_after_expand" then
    line_a, line_b = adjust_expand_lines(line_a, line_b)
  end
  u.enter_visual_mode()
  u.goto_char_col(col_a)
  u.switch_visual()
  u.goto_char_col(col_b)
  floating_window.next_waypoint()
  u.exit_visual_mode()
  floating_window.next_waypoint()
  u.goto_char_col(1)

  if test_type == "reselect_after_shrink" then
    floating_window.reset_context()
  elseif test_type == "reselect_after_expand" then
    expand_context()
  end
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(line_b, col_b, line_a, col_a)
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.move_to_first_waypoint()
  floating_window.reset_context()
end

---@param test_type nil | "reselect_after_shrink" | "reselect_after_expand"
local function reselect_interior_line(test_type)
  local line_a = 4
  local line_b = 4

  if test_type == "reselect_after_shrink" then
    expand_context()
  elseif test_type == "reselect_after_expand" then
    line_a, line_b = adjust_expand_lines(line_a, line_b)
  end
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  u.enter_visual_mode()
  u.goto_char_col(col_a)
  u.switch_visual()
  u.goto_char_col(col_b)
  floating_window.draw_waypoint_window() -- have to put this in here to give the waypoint window a chance to save the visual position
  u.exit_visual_mode()
  floating_window.prev_waypoint()
  u.goto_char_col(1)

  if test_type == "reselect_after_shrink" then
    floating_window.reset_context()
  elseif test_type == "reselect_after_expand" then
    expand_context()
  end
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(line_b, col_b, line_a, col_a)
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.move_to_first_waypoint()
  floating_window.reset_context()
end

---@param test_type nil | "reselect_after_shrink" | "reselect_after_expand"
local function reselect_two_interior_lines(test_type)
  local line_a = 3
  local line_b = 4

  if test_type == "reselect_after_shrink" then
    expand_context()
  elseif test_type == "reselect_after_expand" then
    line_a, line_b = adjust_expand_lines(line_a, line_b)
  end
  floating_window.next_waypoint()
  floating_window.next_waypoint()
  u.enter_visual_mode()
  u.goto_char_col(col_a)
  u.switch_visual()
  floating_window.next_waypoint()
  u.goto_char_col(col_b)
  floating_window.draw_waypoint_window() -- have to put this in here to give the waypoint window a chance to save the visual position
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.prev_waypoint()

  if test_type == "reselect_after_shrink" then
    floating_window.reset_context()
  elseif test_type == "reselect_after_expand" then
    expand_context()
  end
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(line_b, col_b, line_a, col_a)
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.move_to_first_waypoint()
  floating_window.reset_context()
end

---@param test_type nil | "reselect_after_shrink" | "reselect_after_expand"
local function reselect_all_lines(test_type)
  local line_a = 1
  local line_b = num_waypoints
  if test_type == "reselect_after_shrink" then
    expand_context()
  elseif test_type == "reselect_after_expand" then
    line_a, line_b = adjust_expand_lines(line_a, line_b)
  end
  u.enter_visual_mode()
  u.goto_char_col(col_a)
  u.switch_visual()
  floating_window.move_to_last_waypoint()
  u.goto_char_col(col_b)
  floating_window.draw_waypoint_window() -- have to put this in here to give the waypoint window a chance to save the visual position
  u.exit_visual_mode()
  floating_window.prev_waypoint()
  floating_window.prev_waypoint()
  u.goto_char_col(1)

  if test_type == "reselect_after_shrink" then
    floating_window.reset_context()
  elseif test_type == "reselect_after_expand" then
    expand_context()
  end
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(line_b, col_b, line_a, col_a)
  u.exit_visual_mode()
  u.goto_char_col(1)
  floating_window.move_to_first_waypoint()
  floating_window.reset_context()
end

describe('Visual reselect', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_reselect/waypoints.json"
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  floating_window.open()

  -- All these are for 0 context (A, B, and C):
  reselect_beginning_line()
  reselect_beginning_two_lines()
  reselect_interior_line()
  reselect_two_interior_lines()
  reselect_all_lines()

  -- All these are for starting at 0 context, then increasing, then reselecting.
  reselect_beginning_line("reselect_after_shrink")
  reselect_beginning_two_lines("reselect_after_shrink")
  reselect_interior_line("reselect_after_shrink")
  reselect_two_interior_lines("reselect_after_shrink")
  reselect_all_lines("reselect_after_shrink")

  -- All these are for starting at 5 context, then increasing, then reselecting.
  reselect_beginning_line("reselect_after_expand")
  reselect_beginning_two_lines("reselect_after_expand")
  reselect_interior_line("reselect_after_expand")
  reselect_two_interior_lines("reselect_after_expand")
  reselect_all_lines("reselect_after_expand")
end)

describe('Visual reselect deleted', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_reselect/waypoints.json"
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  floating_window.open()
  floating_window.move_to_last_waypoint()
  u.enter_visual_mode()
  floating_window.prev_waypoint()
  floating_window.delete_curr()
  floating_window.move_to_first_waypoint()
  floating_window.reselect_visual()
  tu.assert_eq(state.wpi, #state.waypoints)
  tu.assert_eq(state.vis_wpi, #state.waypoints)
end)

describe('Visual reselect invisible', function()
  print(state.wpi, state.vis_wpi)
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/visual_reselect/waypoints.json"
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)

  floating_window.open()
  floating_window.move_to_last_waypoint()
  u.enter_visual_mode()
  floating_window.prev_waypoint()
  u.exit_visual_mode()
  floating_window.draw_waypoint_window() -- force redraw so waypoint tracks that we exited visual mode
  floating_window.leave()

  tu.edit_file(file_1)
  -- delete lines 8 and 9
  u.goto_line(8)
  tu.normal("dd")
  tu.normal("dd")

  floating_window.open()
  floating_window.move_to_first_waypoint()
  floating_window.reselect_visual()
  tu.assert_vis_char_pos(
    num_waypoints - 2, 1,
    num_waypoints - 2, 1
  )
end)

