local M = {}

M.augroup = "waypoint"
M.hl_group = "waypoint_hl"
M.hl_selected = "waypoint_hl_selected"
M.ns = vim.api.nvim_create_namespace(M.augroup)
M.color = "#9999ff"
M.window_width = 0.8
M.window_height = 0.7
M.file = "./waypoints.json"

M.default_config = {
  annotation_color = "#9999ff",
  mark_color = "#ff9999",
  window_width = 0.8,
  window_height = 0.7,
  file = "./nvim-waypoints.json",
}

return M
