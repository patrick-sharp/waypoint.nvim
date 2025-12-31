local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json
local wp_1_text = test_list.wp_1_text
local wp_2_text = test_list.wp_2_text
local wp_3_text = test_list.wp_3_text

local crud = require("waypoint.waypoint_crud")
local constants = require('waypoint.constants')
local floating_window = require("waypoint.floating_window")
local state = require("waypoint.state")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

describe('Undo crud', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))

  floating_window.open()
  floating_window.undo()
  floating_window.close()

  tu.assert_eq(constants.msg_at_earliest_change, tu.get_last_message())

  vim.cmd.edit({args = {file_0}, bang=true})
  vim.cmd.normal({args = {"7G"}, bang=true})
  crud.append_waypoint_wrapper()

  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(7, state.waypoints[1].linenr)

  floating_window.open()
  floating_window.undo()
  floating_window.close()

  vim.cmd.edit({args = {file_1}, bang=true})
  vim.cmd.normal({args = {"8G"}, bang=true})
  crud.append_waypoint_wrapper()
  vim.cmd.normal({args = {"5G"}, bang=true})
  crud.append_waypoint_wrapper()
  vim.cmd.edit({args = {file_0}, bang=true})
  vim.cmd.normal({args = {"3G"}, bang=true})
  crud.append_waypoint_wrapper()
  vim.cmd.normal({args = {"17G"}, bang=true})
  crud.append_waypoint_wrapper()
end)
