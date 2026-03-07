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
---@field debug_file string
---@field test_output_file string
---@field is_release boolean
---@field error_file_dne string
---@field error_line_oob string
---@field error_no_matching_waypoint string
local M = {
  augroup = augroup,
  background_window_hpadding = 2,
  background_window_vpadding = 1,
  command_relocate = "WaypointRelocate",
  command_reset =    "WaypointReset",
  debug_file = "./debug.log",
  error_file_dne =             "Error: file does not exist",
  error_line_oob =             "Error: line number is out of bounds",
  error_no_matching_waypoint = "Error: could not find a close enough match for this waypoint",
  highlights_on = true,
  hl_directory =             "waypoint_hl_directory",
  hl_footer_after_context =  "waypoint_hl_footer_a",
  hl_footer_before_context = "waypoint_hl_footer_b",
  hl_footer_context =        "waypoint_hl_footer_c",
  hl_footer_waypoint_nr =    "waypoint_hl_footer_nr",
  hl_group =                 "waypoint_hl",
  hl_keybinding =            "waypoint_hl_keybinding",
  hl_linenr =                "waypoint_hl_linenr",
  hl_selected =              "waypoint_hl_selected",
  hl_sign =                  "waypoint_hl_sign",
  hl_toggle_off =            "waypoint_hl_toggle_off",
  hl_toggle_on =             "waypoint_hl_toggle_on",
  is_release = false,
  max_indent = 16,
  ns = vim.api.nvim_create_namespace(augroup),
  table_separator = '│',
  test_output_file = "./test_output.txt",
  window_augroup = window_augroup,
}

return M
