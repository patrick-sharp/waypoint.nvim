local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_1 = "lua/waypoint/test/tests/scroll/file_1.lua"
local waypoints_json = "lua/waypoint/test/tests/scroll/waypoints.json"

local file = require'waypoint.file'
local floating_window = require("waypoint.floating_window")
local message = require'waypoint.message'
local state = require("waypoint.state")
local constants = require("waypoint.constants")
local tu = require'waypoint.test.util'
local u = require("waypoint.utils")

describe('Scroll', function()
  assert(u.file_exists(file_1))
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)
  floating_window.open()

  local view
  view = vim.fn.winsaveview()
  tu.assert_eq(0, view.leftcol)
  tu.assert_eq(0, state.view.leftcol)

  --- 445 is longest line width in file
  local sep = u.vislen(constants.table_separator) + 2
  local longest_line_width = 1 + sep + #file_1 + sep + #"18" + sep + 445

  local window_width = floating_window.get_floating_window_width()

  local right_scroll_cols = 7
  local left_scroll_cols_1 = 5
  local left_scroll_cols_2 = 3

  if (window_width + right_scroll_cols) < longest_line_width then
    for _=1,right_scroll_cols do floating_window.scroll_right() end
    view = vim.fn.winsaveview()
    tu.assert_eq(right_scroll_cols, state.view.leftcol)
    tu.assert_eq(right_scroll_cols, view.leftcol)

    local net_scroll_cols_1 = right_scroll_cols - left_scroll_cols_1

    for _=1,left_scroll_cols_1 do floating_window.scroll_left() end
    view = vim.fn.winsaveview()
    tu.assert_eq(net_scroll_cols_1, view.leftcol)
    tu.assert_eq(net_scroll_cols_1, state.view.leftcol)

    for _=1,left_scroll_cols_2 do floating_window.scroll_left() end
    view = vim.fn.winsaveview()
    tu.assert_eq(0, view.leftcol)
    tu.assert_eq(0, state.view.leftcol)

    for _=1,longest_line_width do floating_window.scroll_right() end
    view = vim.fn.winsaveview()
    tu.assert_eq(longest_line_width - window_width, view.leftcol)
    tu.assert_eq(longest_line_width - window_width, state.view.leftcol)

    floating_window.reset_scroll()
    view = vim.fn.winsaveview()
    tu.assert_eq(0, view.leftcol)
    tu.assert_eq(0, state.view.leftcol)
  else
    message.notify("Your screen is too wide for the scroll test", vim.log.levels.INFO)
  end
end)
