local M = {}

M.augroup = "waypoint"
M.hl_group = "waypoint_hl"
M.waypoint_ns = vim.api.nvim_create_namespace(M.augroup)
M.color = "#0000ff"
M.float_width = 0.8
M.float_height = 0.7

return M
