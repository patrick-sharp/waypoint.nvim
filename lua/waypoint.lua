-- wiki article for type annotations for the lua language server:
-- https://luals.github.io/wiki/annotations

local M = {}

local floating_window = require("waypoint.floating_window")
local crud = require("waypoint.crud")
local file = require("waypoint.file")
local constants = require("waypoint.constants")

function M.setup(opts)
  vim.api.nvim_create_augroup(constants.augroup, { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = constants.augroup,
    callback = file.load,
    once = true,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = constants.augroup,
    callback = file.save,
    once = true,
  })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>f', floating_window.open, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>m', crud.toggle_waypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>s', file.save, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>l', file.load, { noremap = true })
end

return M
