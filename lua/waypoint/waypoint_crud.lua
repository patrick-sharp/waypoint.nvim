local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")


---@param filepath   string
---@param line_nr    integer
---@param annotation string | nil
function M.add_waypoint(filepath, line_nr, annotation)
  if not u.is_file_buffer() then return end
  local bufnr = vim.fn.bufnr(filepath)
  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.ns, line_nr - 1, -1, {
    id = line_nr,
    sign_text = config.mark_char,
    priority = 1,
    sign_hl_group = constants.hl_sign,
  })

  ---@type waypoint.Waypoint
  local waypoint = {
    extmark_bufnr = bufnr,
    extmark_id = extmark_id,
    filepath = filepath,
    indent = 0,
    annotation = annotation,
  }

  table.insert(state.waypoints, waypoint)
  state.wpi = #state.waypoints
end


--- @param filepath string the path of the file to find the waypoint in
--- @param linenr integer the one-indexed line number to look for the waypoint on
--- @return integer the one-indexed index of the waypoint if found, or -1 if not
function M.find_waypoint(filepath, linenr)
  local bufnr = vim.fn.bufnr(filepath)
  for i, waypoint in ipairs(state.waypoints) do
    if waypoint.filepath == filepath then
      local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, constants.ns, waypoint.extmark_id, {})
      local extmark_row = extmark[1] + 1 -- have to do this because extmark line numbers are 0 indexed
      if extmark_row == linenr then
        return i
      end
    end
  end
  return -1
end


function M.remove_waypoint(existing_waypoint_i, filepath)
  local bufnr = vim.fn.bufnr(filepath)

  ---@type waypoint.Waypoint
  local existing_waypoint = state.waypoints[existing_waypoint_i]
  vim.api.nvim_buf_del_extmark(bufnr, constants.ns, existing_waypoint.extmark_id)

  --- @type table<waypoint.Waypoint>
  local waypoints_new = {}
  for _, waypoint in pairs(state.waypoints) do
    if not (waypoint.extmark_id == existing_waypoint.extmark_id) then
      table.insert(waypoints_new, waypoint)
    end
  end
  state.waypoints = waypoints_new
end


function M.toggle_waypoint()
  if not u.is_file_buffer() then return end

  --- @type string
  local filepath = vim.fn.expand("%")

  --- @type integer
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number

  --- @type integer
  local existing_waypoint_i = M.find_waypoint(filepath, cur_line_nr)

  if existing_waypoint_i == -1 then
    M.add_waypoint(filepath, cur_line_nr)
  else
    M.remove_waypoint(existing_waypoint_i, filepath)
  end
end


return M
