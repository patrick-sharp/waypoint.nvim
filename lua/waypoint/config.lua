---@class Config
---@field color_sign string
---@field color_footer_after_context string
---@field color_footer_before_context string
---@field color_footer_context string
---@field window_width number
---@field window_height number
---@field file string
---@field mark_char string
---@field telescope_filename_width integer
---@field telescope_linenr_width integer
---@field indent_width integer
---@field enable_highlight boolean
local M = {
  color_sign = "NONE",
  color_footer_after_context = "#ff7777",
  color_footer_before_context = "#77ff77",
  color_footer_context = "#7777ff",
  window_width = 0.8,
  window_height = 0.8,
  file = "./nvim-waypoints.json",
  mark_char = "◆",
  telescope_filename_width = 30,
  telescope_linenr_width = 5,
  indent_width = 6,
  enable_highlight = true,
}

return M
