-- wiki article for type annotations for the lua language server:
-- https://luals.github.io/wiki/annotations

local M = {}

local floating_window = require("waypoint.floating_window")
local crud = require("waypoint.waypoint_crud")
local file = require("waypoint.file")
local constants = require("waypoint.constants")
local config = require("waypoint.config")
local p = require("waypoint.print")

function M.setup(opts)
  -- set up config
  for k, v in pairs(opts) do
    local default_val = config[k]
    assert(default_val, "property \"" .. k .. "\" does not exist in waypoint config")
    assert(type(v) == type(default_val), "expected the value for property \"" ..  k .. "\" to be of type " .. type(default_val) .. ", but was of type " .. type(v))
    config[k] = v
  end
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

  vim.keymap.set({ 'n', 'v' }, 'mc', floating_window.GoToCurrentWaypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, 'mn', floating_window.GoToNextWaypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, 'mp', floating_window.GoToPrevWaypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, 'mg', floating_window.GoToFirstWaypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, 'mG', floating_window.GoToLastWaypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, 'mf', floating_window.open, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, 'mt', crud.toggle_waypoint, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>s', file.save, { noremap = true })
  vim.keymap.set({ 'n', 'v' }, '<leader><leader>l', file.load, { noremap = true })
end

return M
