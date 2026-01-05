local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json
local wp_1_text = test_list.wp_1_text
local wp_2_text = test_list.wp_2_text
local wp_3_text = test_list.wp_3_text

local crud = require("waypoint.waypoint_crud")
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local uw = require('waypoint.utils_waypoint')

describe('Annotation', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))

  local annotation_1 = "Annotation #1"
  local annotation_2 = "Annotation #2"
  local annotation_3 = "Annotation #3"

  vim.cmd.edit({args = {file_0}, bang=true})
  tu.goto_line(7)
  crud.append_annotated_waypoint(annotation_1) -- waypoint 1
  vim.cmd.edit({args = {file_1}, bang=true})
  tu.goto_line(8)
  crud.append_waypoint_wrapper()               -- waypoint 2
  tu.goto_line(5)
  crud.append_annotated_waypoint(annotation_2) -- waypoint 5
  vim.cmd.edit({args = {file_0}, bang=true})
  tu.goto_line(3)
  crud.append_waypoint_wrapper()               -- waypoint 6

  -- test insert
  floating_window.next_waypoint()
  tu.goto_line(17)
  crud.insert_annotated_waypoint(annotation_3) -- waypoint 3
  tu.goto_line(15)
  crud.insert_waypoint_wrapper()               -- waypoint 4

  floating_window.open()
  local lines = tu.get_waypoint_buffer_lines_trimmed()

  tu.assert_eq(6, #state.waypoints)

  local i

  i = 1
  tu.assert_eq(7, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq(annotation_1, state.waypoints[i].annotation)
  tu.assert_eq(annotation_1, lines[i][4])

  i = 2
  tu.assert_eq(8, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq("table.insert(t, i)", lines[i][4])

  i = 3
  tu.assert_eq(17, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq(annotation_3, state.waypoints[i].annotation)
  tu.assert_eq(annotation_3, lines[i][4])

  i = 4
  tu.assert_eq(15, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq("end", lines[i][4])

  i = 5
  tu.assert_eq(5, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq(annotation_2, state.waypoints[i].annotation)
  tu.assert_eq(annotation_2, lines[i][4])

  i = 6
  tu.assert_eq(3, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq("function M.fn_0()", lines[i][4])
end)
