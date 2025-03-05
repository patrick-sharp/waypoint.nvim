-- wiki article for type annotations for the lua language server:
-- https://luals.github.io/wiki/annotations

local M = {}

local floating_window = require("waypoint.floating_window")
local crud = require("waypoint.crud")
local file = require("waypoint.file")

function M.setup(opts)
  vim.api.nvim_create_augroup("waypoint", { clear = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>f', floating_window.open, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>m', crud.toggle_waypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>s', file.save, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>l', file.load, { noremap = true })
end

return M
