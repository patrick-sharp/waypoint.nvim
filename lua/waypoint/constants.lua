local M = {}

M.augroup = "waypoint"
M.hl_group = "waypoint_hl"
M.hl_selected = "waypoint_hl_selected"
M.hl_sign = "waypoint_hl_sign"
M.hl_annotation = "waypoint_hl_annotation"
M.ns = vim.api.nvim_create_namespace(M.augroup)

return M
