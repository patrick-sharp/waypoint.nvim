local M = {}

local config = require("waypoint.constants")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local utils = require("waypoint.utils")

function M.add_waypoint(filepath, line_nr)
  local bufnr = vim.fn.bufnr(filepath)
  local annotation = "<======> Highlighted Text"
  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.ns, line_nr - 1, -1, {
    id = line_nr,
    sign_text = ">",
    priority = 1,
    sign_hl_group = constants.hl_group,
    virt_text = { {annotation, constants.hl_group} },  -- "Error" is a predefined highlight group
    virt_text_pos = "eol",  -- Position at end of line
  })

  ---@type Waypoint
  local waypoint = {
    annotation = annotation,
    extmark_id = extmark_id,
    filepath = filepath,
    indent = 0,
  }

  table.insert(state.waypoints, waypoint)
end

function M.remove_waypoint(existing_waypoint_i, filepath)
  local bufnr = vim.fn.bufnr(filepath)

  ---@type Waypoint
  local existing_waypoint = state.waypoints[existing_waypoint_i]
  vim.api.nvim_buf_del_extmark(bufnr, constants.ns, existing_waypoint.extmark_id)

  --- @type table<Waypoint>
  local waypoints_new = {}
  for _, waypoint in pairs(state.waypoints) do
    if not (waypoint.extmark_id == existing_waypoint.extmark_id) then
      table.insert(waypoints_new, waypoint)
    end
  end
  state.waypoints = waypoints_new
end

function M.toggle_waypoint()
  --- @type string
  local filepath = vim.fn.expand("%")

  --- @type integer
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number

  --- @type integer
  local existing_waypoint_i = utils.buf_find_waypoint(cur_line_nr)

  if existing_waypoint_i == -1 then
    M.add_waypoint(filepath, cur_line_nr)
  else
    M.remove_waypoint(existing_waypoint_i, filepath)
  end
  vim.cmd("highlight " .. constants.hl_sign .. " guifg=" .. config.sign_color .. " guibg=NONE") -- Blue text, no background
end

return M
