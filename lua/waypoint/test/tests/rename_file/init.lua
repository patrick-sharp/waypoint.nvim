local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local test_path = "lua/waypoint/test/tests/rename_file/"

local crud = require("waypoint.waypoint_crud")
local floating_window = require("waypoint.floating_window")
local message = require("waypoint.message")
local state = require("waypoint.state")
local tu = require'waypoint.test.util'
local u = require("waypoint.util")
local uw = require("waypoint.util_waypoint")

-- get rid of uv warnings in this file
---@diagnostic disable: undefined-field

describe('Rename file', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))

  local uv = vim.uv or vim.loop  -- Compatibility for different Neovim versions

  local old_name = "example_file.txt"
  local new_name = "renamed_file.txt"

  local old_path = vim.fs.joinpath(test_path, old_name)
  local new_path = vim.fs.joinpath(test_path, new_name)

  local content = "example\nfile\ntext\n" .. os.date()

  local fd = uv.fs_open(old_path, "w", 438)
  assert(fd)
  assert(uv.fs_write(fd, content, -1))
  tu.edit_file(old_path)
  u.goto_line(2)
  crud.insert_waypoint_wrapper()
  vim.cmd.saveas({ args = { new_path }, bang = true })
  assert(uv.fs_unlink(old_path))

  floating_window.open()
  floating_window.jump_to_waypoint()

  local curr_file_path = vim.api.nvim_buf_get_name(0)
  tu.assert_eq(new_path, u.relative_path(curr_file_path))

  local curr_linenr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  local wp_linenr = uw.linenr_from_waypoint(state.waypoints[1])
  tu.assert_eq(wp_linenr, curr_linenr)

  assert(uv.fs_close(fd))
  assert(uv.fs_unlink(new_path))
end)

describe('Rename closed file', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))

  local uv = vim.uv or vim.loop  -- Compatibility for different Neovim versions

  local old_name = "example_file.txt"
  local new_name = "renamed_file.txt"

  local old_path = vim.fs.joinpath(test_path, old_name)
  local new_path = vim.fs.joinpath(test_path, new_name)

  local content = "example\nfile\ntext\n" .. os.date()

  local fd = uv.fs_open(old_path, "w", 438)
  assert(fd)
  assert(uv.fs_write(fd, content, -1))
  tu.edit_file(old_path)
  u.goto_line(2)
  crud.insert_waypoint_wrapper()
  -- close current buffer
  vim.api.nvim_buf_delete(vim.fn.bufnr(), { force = true })
  assert(uv.fs_close(fd))
  -- rename file
  uv.fs_rename(old_path, new_path)
  -- reopen file
  tu.edit_file(new_path)

  floating_window.open()
  local lines = tu.get_waypoint_buffer_lines_trimmed()
  assert(message.missing_file_err_msg, lines[1][4])
  assert(uv.fs_unlink(new_path))
end)
