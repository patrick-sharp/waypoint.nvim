local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1
local waypoints_json = test_list.waypoints_json

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'

describe('Quickfix list', function()
  local qflist

  floating_window.open()
  floating_window.set_quickfix_list()
  qflist = vim.fn.getqflist()

  tu.assert_eq(0, u.len(qflist))

  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)
  floating_window.open()

  floating_window.set_quickfix_list()
  qflist = vim.fn.getqflist()

  tu.assert_eq(test_list.num_waypoints, u.len(qflist))
  tu.assert_eq(test_list.wp_1_lnum, qflist[1].lnum)
  tu.assert_eq(test_list.wp_2_lnum, qflist[2].lnum)
  tu.assert_eq(test_list.wp_3_lnum, qflist[3].lnum)

  tu.assert_eq(test_list.wp_1_text, vim.trim(qflist[1].text))
  tu.assert_eq(test_list.wp_2_text, vim.trim(qflist[2].text))
  tu.assert_eq(test_list.wp_3_text, vim.trim(qflist[3].text))

  tu.assert_eq(vim.fn.bufnr(file_0), qflist[1].bufnr)
  tu.assert_eq(vim.fn.bufnr(file_1), qflist[2].bufnr)
  tu.assert_eq(vim.fn.bufnr(file_1), qflist[3].bufnr)
end)
