-- wiki article for type annotations for the lua language server:
-- https://luals.github.io/wiki/annotations

local M = {}

local floating_window = require("waypoint.floating_window")
local crud = require("waypoint.crud")

function M.setup(opts)
  vim.api.nvim_create_augroup("waypoint", { clear = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>f', floating_window.open, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>m', crud.toggle_waypoint, { noremap = true })
end

return M
