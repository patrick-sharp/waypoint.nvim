local test_list = require"waypoint.test.test_list"
local describe = test_list.describe

local config = require"waypoint.config"
local crud = require"waypoint.waypoint_crud"
local state = require"waypoint.state"
local u = require"waypoint.utils"
local uw = require"waypoint.utils_waypoint"
local tu = require"waypoint.test.util"

local lines_before = {
  "one  ",
  "two  ",
  "three",
  "four ",
  "five ",
  "six  ",
  "seven",
  "eight",
  "nine "
}

-- (DONE) first case
-- make three extmarks
-- filter text with grep outside extmark range
-- what happens?

-- (DONE) second case
-- make three extmarks
-- filter text with grep inside extmark range
-- what happens?

-- third case
-- make three extmarks
-- filter text with grep inside extmark range
-- undo
-- delete marks with md
-- make sure marks are deleted

-- fourth case
-- make three extmarks
-- filter text with grep inside extmark range that vomits garbage into the buffer
-- undo
-- delete marks with md
-- make sure marks are deleted

-- I have no idea why the extra space shows up in extmark text
local visible_extmark_text = config.mark_char .. " "
local invisible_extmark_text = "  "

describe('Filter moves no waypoints', function()
  local wp_1_linenr = 3
  local wp_2_linenr = 4
  local wp_3_linenr = 6

  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines_before)
  vim.api.nvim_set_current_buf(bufnr)

  u.goto_line(wp_1_linenr)
  crud.append_waypoint_wrapper()
  u.goto_line(wp_2_linenr)
  crud.append_waypoint_wrapper()
  u.goto_line(wp_3_linenr)
  crud.append_waypoint_wrapper()

  local extmarks
  extmarks = uw.buf_get_extmarks(bufnr)

  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(visible_extmark_text, extmarks[2][4].sign_text)
  tu.assert_eq(wp_3_linenr - 1, extmarks[3][2])
  tu.assert_eq(visible_extmark_text, extmarks[3][4].sign_text)

  vim.cmd("7,9!grep eight")

  -- filter should not change location of extmarks
  extmarks = uw.buf_get_extmarks(bufnr)
  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(visible_extmark_text, extmarks[2][4].sign_text)
  tu.assert_eq(wp_3_linenr - 1, extmarks[3][2])
  tu.assert_eq(visible_extmark_text, extmarks[3][4].sign_text)

  tu.assert_eq(3, #state.waypoints)
  u.goto_line(wp_1_linenr)
  crud.delete_waypoint()
  tu.assert_eq(2, #state.waypoints)
  u.goto_line(wp_2_linenr)
  crud.delete_waypoint()
  tu.assert_eq(1, #state.waypoints)
  u.goto_line(wp_3_linenr)
  crud.delete_waypoint()
  tu.assert_eq(0, #state.waypoints)

  -- deleting should make extmarks invisible
  extmarks = uw.buf_get_extmarks(bufnr)
  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(invisible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(invisible_extmark_text, extmarks[2][4].sign_text)
  tu.assert_eq(wp_3_linenr - 1, extmarks[3][2])
  tu.assert_eq(invisible_extmark_text, extmarks[3][4].sign_text)
end)

describe('Filter moves waypoint', function()
  local wp_1_linenr = 3
  local wp_2_linenr = 4
  local wp_3_linenr = 8

  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines_before)
  vim.api.nvim_set_current_buf(bufnr)

  u.goto_line(wp_1_linenr)
  crud.append_waypoint_wrapper()
  u.goto_line(wp_2_linenr)
  crud.append_waypoint_wrapper()
  u.goto_line(wp_3_linenr)
  crud.append_waypoint_wrapper()

  local extmarks
  extmarks = uw.buf_get_extmarks(bufnr)

  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(visible_extmark_text, extmarks[2][4].sign_text)
  tu.assert_eq(wp_3_linenr - 1, extmarks[3][2])
  tu.assert_eq(visible_extmark_text, extmarks[3][4].sign_text)

  vim.cmd("7,9!grep eight")

  -- filter should not change location of extmarks
  extmarks = uw.buf_get_extmarks(bufnr)
  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(visible_extmark_text, extmarks[2][4].sign_text)
  -- this waypoint should be moved up one
  tu.assert_eq(wp_3_linenr - 2, extmarks[3][2])
  tu.assert_eq(visible_extmark_text, extmarks[3][4].sign_text)

  tu.assert_eq(3, #state.waypoints)
  u.goto_line(wp_1_linenr)
  crud.delete_waypoint()
  tu.assert_eq(2, #state.waypoints)
  u.goto_line(wp_2_linenr)
  crud.delete_waypoint()
  tu.assert_eq(1, #state.waypoints)
  u.goto_line(wp_3_linenr - 1)
  crud.delete_waypoint()
  tu.assert_eq(0, #state.waypoints)

  -- deleting should make extmarks invisible
  extmarks = uw.buf_get_extmarks(bufnr)
  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(invisible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(invisible_extmark_text, extmarks[2][4].sign_text)
  tu.assert_eq(wp_3_linenr - 2, extmarks[3][2])
  tu.assert_eq(invisible_extmark_text, extmarks[3][4].sign_text)
end)

describe('Filter deletes waypoint', function()
  local wp_1_linenr = 3
  local wp_2_linenr = 4
  local wp_3_linenr = 8

  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines_before)
  vim.api.nvim_set_current_buf(bufnr)

  u.goto_line(wp_1_linenr)
  crud.append_waypoint_wrapper()
  u.goto_line(wp_2_linenr)
  crud.append_waypoint_wrapper()
  u.goto_line(wp_3_linenr)
  crud.append_waypoint_wrapper()

  local extmarks
  extmarks = uw.buf_get_extmarks(bufnr)

  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(visible_extmark_text, extmarks[2][4].sign_text)
  tu.assert_eq(wp_3_linenr - 1, extmarks[3][2])
  tu.assert_eq(visible_extmark_text, extmarks[3][4].sign_text)

  vim.cmd("7,9!grep seven")

  -- filter should not change location of extmarks
  extmarks = uw.buf_get_extmarks(bufnr)
  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(visible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(visible_extmark_text, extmarks[2][4].sign_text)
  -- this extmark should be deleted
  tu.assert_eq(true, extmarks[3][4].invalid)
  tu.assert_eq(visible_extmark_text, extmarks[3][4].sign_text)

  tu.assert_eq(3, #state.waypoints)
  u.goto_line(wp_1_linenr)
  crud.delete_waypoint()
  tu.assert_eq(2, #state.waypoints)
  u.goto_line(wp_2_linenr)
  crud.delete_waypoint()
  tu.assert_eq(1, #state.waypoints)
  u.goto_line(wp_3_linenr)
  crud.delete_waypoint()
  -- cannot delete waypoint that should not be drawn
  tu.assert_eq(1, #state.waypoints)
  tu.assert_eq(false, uw.should_draw_waypoint(state.waypoints[1]))
  --
  -- deleting should make extmarks invisible
  extmarks = uw.buf_get_extmarks(bufnr)
  tu.assert_eq(3, #extmarks)
  tu.assert_eq(wp_1_linenr - 1, extmarks[1][2])
  tu.assert_eq(invisible_extmark_text, extmarks[1][4].sign_text)
  tu.assert_eq(wp_2_linenr - 1, extmarks[2][2])
  tu.assert_eq(invisible_extmark_text, extmarks[2][4].sign_text)
  tu.assert_eq(wp_3_linenr - 2, extmarks[3][2])
  tu.assert_eq(visible_extmark_text, extmarks[3][4].sign_text)
end)

describe('Filter outputs garbage', function()

end)

