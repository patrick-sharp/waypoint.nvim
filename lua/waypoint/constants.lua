local augroup = "waypoint"

---@class Constants
---@field augroup string
---@field hl_group string
---@field hl_selected string
---@field hl_sign string
---@field hl_footer_after_context string
---@field hl_footer_before_context string
---@field hl_footer_context string
---@field ns integer
local M = {
  augroup = augroup,
  hl_group = "waypoint_hl",
  hl_selected = "waypoint_hl_selected",
  hl_sign = "waypoint_hl_sign",
  hl_directory = "waypoint_hl_directory",
  hl_linenr = "waypoint_hl_linenr",
  hl_footer_after_context = "waypoint_hl_footer_a",
  hl_footer_before_context = "waypoint_hl_footer_b",
  hl_footer_context = "waypoint_hl_footer_c",
  ns = vim.api.nvim_create_namespace(augroup),
  table_separator = '│'
  -- table_separator = '|'
}

return M
