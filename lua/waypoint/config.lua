---@class Config
---@field color_annotation string
---@field color_sign string
---@field color_footer_after_context string
---@field color_footer_before_context string
---@field color_footer_context string
---@field window_width number
---@field window_height number
---@field file string
local M = {
  color_annotation = "#9999ff",
  color_sign = "#ff9999",
  color_footer_after_context = "#ff6666",
  color_footer_before_context = "#66ff66",
  color_footer_context = "#6666ff",
  window_width = 0.8,
  window_height = 0.7,
  file = "./nvim-waypoints.json",
}

return M
