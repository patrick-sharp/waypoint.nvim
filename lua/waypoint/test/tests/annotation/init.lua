local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local crud = require("waypoint.waypoint_crud")
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local u = require("waypoint.util")
local tu = require'waypoint.test.util'
local uw = require('waypoint.util_waypoint')

describe('Annotation', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))

  local annotation_1 = "Annotation #1"
  local annotation_2 = "Annotation #2"

  tu.edit_file(file_0)
  u.goto_line(7)
  crud.append_waypoint_wrapper()                                 -- waypoint 1
  -- don't bother programatically entering stuff into the prompt
  state.waypoints[#state.waypoints].annotation = annotation_1
  tu.edit_file(file_1)
  u.goto_line(8)
  crud.append_waypoint_wrapper()                                 -- waypoint 2
  u.goto_line(5)
  crud.append_waypoint_wrapper()                                 -- waypoint 3
  state.waypoints[#state.waypoints].annotation = annotation_2
  tu.edit_file(file_0)
  u.goto_line(3)
  crud.append_waypoint_wrapper()                                 -- waypoint 4

  tu.assert_eq(4, #state.waypoints)

  floating_window.open()
  local lines = tu.get_waypoint_buffer_lines_trimmed()

  local i

  i = 1
  tu.assert_eq(7, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq(annotation_1, state.waypoints[i].annotation)
  tu.assert_eq(annotation_1, lines[i][2])
  tu.assert_eq("function M.fn_1()", lines[i][5])

  i = 2
  tu.assert_eq(8, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq(nil, state.waypoints[i].annotation)
  tu.assert_eq("", lines[i][2])
  tu.assert_eq("table.insert(t, i)", lines[i][5])

  i = 3
  tu.assert_eq(5, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq(annotation_2, state.waypoints[i].annotation)
  tu.assert_eq(annotation_2, lines[i][2])
  tu.assert_eq("function M.fn_0()", lines[i][5])

  i = 4
  tu.assert_eq(3, uw.linenr_from_waypoint(state.waypoints[i]))
  tu.assert_eq(nil, state.waypoints[i].annotation)
  tu.assert_eq("", lines[i][2])
  tu.assert_eq("function M.fn_0()", lines[i][5])
end)
