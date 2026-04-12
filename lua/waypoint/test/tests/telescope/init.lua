
local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local message = require("waypoint.message")
local file = require'waypoint.file'
local u = require("waypoint.util")
local tu = require'waypoint.test.util'

-- this test also tests waypoints not displaying when their extmarks are deleted
describe('Telescope', function()
  local has_telescope, telescope = pcall(require, "telescope")

  -- make the test no-op when telescope is not installed. makes this work with the nvim_clean init.lua file
  if not has_telescope then
     return
  end

  assert(u.file_exists(file_0))
  assert(u.file_exists(file_1))
  local waypoints_json = "lua/waypoint/test/tests/telescope/waypoints.json"
  assert(u.file_exists(waypoints_json))

  file.load_from_file(waypoints_json)
  vim.api.nvim_buf_delete(vim.fn.bufnr(file_0), {})

  local action_state = require('telescope.actions.state')
  local actions = require('telescope.actions')

  telescope.extensions.waypoints.waypoints()

  vim.wait(100, function()
    return action_state.get_current_picker(vim.api.nvim_get_current_buf()) ~= nil
  end)

  local bufnr = vim.api.nvim_get_current_buf()
  local picker = action_state.get_current_picker(bufnr)

  tu.assert_eq(4, #picker.finder.results)

  tu.assert_eq(file_0, picker.finder.results[1].filename)
  tu.assert_eq(1, picker.finder.results[1].lnum)
  tu.assert_eq(message.no_open_buffer_for_file, picker.finder.results[1].text)

  tu.assert_eq(file_0, picker.finder.results[2].filename)
  tu.assert_eq(3, picker.finder.results[2].lnum)
  tu.assert_eq(message.no_open_buffer_for_file, picker.finder.results[2].text)

  tu.assert_eq(file_1, picker.finder.results[3].filename)
  tu.assert_eq(8, picker.finder.results[3].lnum)
  tu.assert_eq("    table.insert(t, i)", picker.finder.results[3].text)

  tu.assert_eq(file_1, picker.finder.results[4].filename)
  tu.assert_eq(9, picker.finder.results[4].lnum)
  tu.assert_eq("  end", picker.finder.results[4].text)

  actions.close(bufnr)
end)
