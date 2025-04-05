local u = require("waypoint.utils")
local p = u.p

local config = require("waypoint.config")
local constants = require("waypoint.constants")

local M = {}

function M.get_syntax_groups_in_current_line()
  local line_num = vim.fn.line('.')
  local line_text = vim.fn.getline(line_num)
  local result = {}

  for col = 1, #line_text do
    local synstack = vim.fn.synstack(line_num, col)
    local groups = {}

    for i = 1, #synstack do
      local synid = synstack[i]
      local name = vim.fn.synIDattr(synid, "name")
      table.insert(groups, name)
    end

    if #groups > 0 then
      result[col] = groups
    end
  end

  return result
end

function M.wa()
  print("WAAAA")
  local highlights = M.get_syntax_groups_in_current_line()
end

function M.ha()
  local synstack = vim.fn.synstack(vim.fn.line('.'), vim.fn.col('.'))
  local groups = {}

  u.p(synstack)
  for i = 1, #synstack do
    local synid = synstack[i]
    if true then
      synid = vim.fn.synIDtrans(synid)
      local name = vim.fn.synIDattr(synid, "name")
      local hlgroup = vim.api.nvim_get_hl(0, {id = synid})
      local hex_str = string.format("#%x", hlgroup.fg)
      table.insert(groups, {name, hlgroup, hex_str})
    else
      local name = vim.fn.synIDattr(synid, "name")
      table.insert(groups, name)
    end
  end
  u.p(groups)
end


function M.highlight_custom_groups()
  local color_dir_dec = vim.api.nvim_get_hl(0, {name = "Directory"}).fg
  local color_dir_hex = '#' .. string.format("%x", color_dir_dec)

  local color_nr_dec = vim.api.nvim_get_hl(0, {name = "LineNr"}).fg
  local color_nr_hex = '#' .. string.format("%x", color_nr_dec)

  local color_cursor_line_dec = vim.api.nvim_get_hl(0, {name = "StatusLine"}).bg
  local color_cursor_line_hex = '#' .. string.format("%x", color_cursor_line_dec)

  local hl_def = vim.api.nvim_get_hl_by_name('NormalFloat', true)
  local bg_color = string.format('#%06x', hl_def.background)

  vim.cmd("highlight " .. constants.hl_selected .. " guibg=" .. color_cursor_line_hex)
  vim.cmd("highlight " .. constants.hl_sign .. " guifg=" .. config.color_sign .. " guibg=NONE")
  vim.cmd("highlight " .. constants.hl_directory .. " guifg=" .. color_dir_hex)
  vim.cmd("highlight " .. constants.hl_linenr .. " guifg=" .. color_nr_hex)
  vim.cmd("highlight " .. constants.hl_footer_after_context .. " guifg=" .. config.color_footer_after_context .. " guibg=" .. bg_color)
  vim.cmd("highlight " .. constants.hl_footer_before_context .. " guifg=" .. config.color_footer_before_context .. " guibg=" .. bg_color)
  vim.cmd("highlight " .. constants.hl_footer_context .. " guifg=" .. config.color_footer_context .. " guibg=" .. bg_color)
  vim.cmd("highlight " .. constants.hl_footer_waypoint_nr ..  " guibg=" .. bg_color)
  --vim.cmd("highlight " .. constants.hl_footer_waypoint_nr .. " guifg=NONE" .. " guibg=" .. bg_color)
end

return M
