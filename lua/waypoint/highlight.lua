local u = require("waypoint.utils")
local p = u.p

local config = require("waypoint.config")
local constants = require("waypoint.constants")

local M = {}

function M.highlight_custom_groups()
  local color_dir_dec = vim.api.nvim_get_hl(0, {name = "Directory"}).fg
  local color_dir_hex = '#' .. string.format("%x", color_dir_dec)

  local color_nr_dec = vim.api.nvim_get_hl(0, {name = "LineNr"}).fg
  local color_nr_hex = '#' .. string.format("%x", color_nr_dec)

  local color_cursor_line_dec = vim.api.nvim_get_hl(0, {name = "StatusLine"}).bg
  local color_cursor_line_hex = '#' .. string.format("%x", color_cursor_line_dec)

  local hl_def = vim.api.nvim_get_hl_by_name('FloatBorder', true)
  local bg_color = "NONE"
  if hl_def.background then
    bg_color = string.format('#%06x', hl_def.background)
  end

  vim.cmd("highlight " .. constants.hl_selected .. " guibg=" .. color_cursor_line_hex)
  vim.cmd("highlight " .. constants.hl_sign .. " guifg=" .. config.color_sign .. " guibg=NONE")
  vim.cmd("highlight " .. constants.hl_directory .. " guifg=" .. color_dir_hex)
  vim.cmd("highlight " .. constants.hl_linenr .. " guifg=" .. color_nr_hex)
  vim.cmd("highlight " .. constants.hl_footer_after_context .. " guifg=" .. config.color_footer_after_context .. " guibg=" .. bg_color)
  vim.cmd("highlight " .. constants.hl_footer_before_context .. " guifg=" .. config.color_footer_before_context .. " guibg=" .. bg_color)
  vim.cmd("highlight " .. constants.hl_footer_context .. " guifg=" .. config.color_footer_context .. " guibg=" .. bg_color)
  vim.cmd("highlight " .. constants.hl_footer_waypoint_nr ..  " guibg=" .. bg_color)
end

return M
