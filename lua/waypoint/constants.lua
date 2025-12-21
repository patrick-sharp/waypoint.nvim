local augroup = "waypoint"
local window_augroup = "waypoint.window"

---@class Constants
---@field augroup string
---@field window_augroup string
---@field hl_group string
---@field hl_selected string
---@field hl_sign string
---@field hl_directory string
---@field hl_footer_after_context string
---@field hl_linenr string
---@field hl_footer_before_context string
---@field hl_footer_context string
---@field hl_footer_waypoint_nr string
---@field hl_toggle_on string
---@field hl_toggle_off string
---@field hl_keybinding string
---@field ns integer
---@field max_indent integer
---@field table_separator string
---@field highlights_on boolean
---@field debug boolean
---@field debug_file string
---@field test_output_file string
---@field is_release boolean
---@field file_dne_error string
---@field line_oob_error string
local M = {
  augroup = augroup,
  window_augroup = window_augroup,
  hl_group = "waypoint_hl",
  hl_selected = "waypoint_hl_selected",
  hl_sign = "waypoint_hl_sign",
  hl_directory = "waypoint_hl_directory",
  hl_linenr = "waypoint_hl_linenr",
  hl_footer_after_context = "waypoint_hl_footer_a",
  hl_footer_before_context = "waypoint_hl_footer_b",
  hl_footer_context = "waypoint_hl_footer_c",
  hl_footer_waypoint_nr = "waypoint_hl_footer_nr",
  hl_toggle_on = "waypoint_hl_toggle_on",
  hl_toggle_off = "waypoint_hl_toggle_off",
  hl_keybinding = "waypoint_hl_keybinding",
  ns = vim.api.nvim_create_namespace(augroup),
  max_indent = 16,
  table_separator = '│',
  -- ┼ ┴ ┬ ╵ ╷ 
  -- table_separator = '|',
  -- table_separator = '-',
  -- table_separator = '–',
  -- table_separator = '—',
  -- table_separator = " ",
  -- table_separator = "   ",
  -- table_separator = "·",
  -- table_separator = "···",
  highlights_on = true,
  debug = true,
  debug_file = "./debug.log",
  test_output_file = "./test_output.txt",
  is_release = false,
  file_dne_error = "Error: file does not exist",
  line_oob_error = "Error: line number is out of bounds",
}

-- candidate indentation styles
-- https://en.wikipedia.org/wiki/Box-drawing_characters

return M
