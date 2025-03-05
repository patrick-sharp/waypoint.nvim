local M = {}

M.augroup = "waypoint"
M.hl_group = "waypoint_hl"
M.hl_selected = "waypoint_hl_selected"
M.ns = vim.api.nvim_create_namespace(M.augroup)
M.color = "#9999ff"
M.float_width = 0.8
M.float_height = 0.7
M.file = "./waypoints.json"

return M
