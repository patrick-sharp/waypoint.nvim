local p = require("waypoint.print")

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local u = require("waypoint.utils")

local M = {}

function M.highlight_custom_groups()
  local color_dir_dec = vim.api.nvim_get_hl(0, {name = "Directory"}).fg
  local color_dir_hex = '#' .. string.format("%x", color_dir_dec)

  local color_nr_dec = vim.api.nvim_get_hl(0, {name = "LineNr"}).fg
  local color_nr_hex = '#' .. string.format("%x", color_nr_dec)

  -- account for some color schemes having cursorlines that are too faint to use compared to float background
  -- the 
  local bg_hl_group
  if u.hl_background_distance("Normal", "NormalFloat") > 300 then
    bg_hl_group = "Normal"
  else
    bg_hl_group = "NormalFloat"
  end

  -- decide whether or not to highlight the currently selected waypoint with statusline or cursorline
  -- sometimes cursorline is too close to the window background color
  local selected_waypoint_hl_group
  local cursor_line_exists = vim.api.nvim_get_hl(0, {name = "CursorLine"}) ~= {}
  local status_line_exists = vim.api.nvim_get_hl(0, {name = "StatusLine"}) ~= {}
  if status_line_exists and cursor_line_exists then
    if u.hl_background_distance(bg_hl_group, "CursorLine") < 40 then
      selected_waypoint_hl_group = "StatusLine"
    else
      selected_waypoint_hl_group = "CursorLine"
    end
  elseif status_line_exists then
    selected_waypoint_hl_group = "StatusLine"
  elseif cursor_line_exists then
    selected_waypoint_hl_group = "CursorLine"
  else
    selected_waypoint_hl_group = "Normal"
  end

  local color_cursor_line_dec = vim.api.nvim_get_hl(0, {name = selected_waypoint_hl_group}).bg
  local color_cursor_line_hex = '#' .. string.format("%x", color_cursor_line_dec)

  local float_border_hl_def = vim.api.nvim_get_hl_by_name('FloatBorder', true)
  local float_border_bg = "NONE"
  if float_border_hl_def.background then
    float_border_bg = string.format('#%06x', float_border_hl_def.background)
  end

  local color_keybinding_dec = vim.api.nvim_get_hl(0, {name = "Special"}).fg
  local color_keybinding_hex = '#' .. string.format("%x", color_keybinding_dec)

  vim.cmd("highlight " .. constants.hl_selected .. " guibg=" .. color_cursor_line_hex)
  vim.cmd("highlight " .. constants.hl_sign .. " guifg=" .. config.color_sign .. " guibg=NONE")
  vim.cmd("highlight " .. constants.hl_directory .. " guifg=" .. color_dir_hex)
  vim.cmd("highlight " .. constants.hl_linenr .. " guifg=" .. color_nr_hex)
  vim.cmd("highlight " .. constants.hl_footer_after_context .. " guifg=" .. config.color_footer_after_context .. " guibg=" .. float_border_bg)
  vim.cmd("highlight " .. constants.hl_footer_before_context .. " guifg=" .. config.color_footer_before_context .. " guibg=" .. float_border_bg)
  vim.cmd("highlight " .. constants.hl_footer_context .. " guifg=" .. config.color_footer_context .. " guibg=" .. float_border_bg)
  vim.cmd("highlight " .. constants.hl_footer_waypoint_nr ..  " guibg=" .. float_border_bg)
  vim.cmd("highlight " .. constants.hl_toggle_on .. " guifg=" .. constants.color_toggle_on)
  vim.cmd("highlight " .. constants.hl_toggle_off .. " guifg=" .. constants.color_toggle_off)
  vim.cmd("highlight " .. constants.hl_keybinding .. " guifg=" .. color_keybinding_hex)
end

return M
