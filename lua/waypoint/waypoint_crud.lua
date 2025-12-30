-- This file contains all methods that modify the waypoints

local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local message = require("waypoint.message")
local undo = require("waypoint.undo")

---@param a waypoint.Waypoint
---@param b waypoint.Waypoint
local function waypoint_compare(a, b)
  if a.filepath == b.filepath then
    return a.linenr < b.linenr
  end
  return a.filepath < b.filepath
end

function M.make_sorted_waypoints()
  state.sorted_waypoints = {}
  for _, waypoint in ipairs(state.waypoints) do
    table.insert(state.sorted_waypoints, waypoint)
  end
  table.sort(state.sorted_waypoints, waypoint_compare)
end

---@param filepath   string
---@param line_nr    integer one-indexed line number
---@param annotation string | nil
function M.append_waypoint(filepath, line_nr, annotation)
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
    extmark_id = extmark_id,
    filepath = filepath,
    indent = 0,
    annotation = annotation,
    linenr = line_nr,
    bufnr = bufnr,
    text = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, true)[1],
    error = nil,
  }

  table.insert(state.waypoints, waypoint)
  M.make_sorted_waypoints()

  state.wpi = state.wpi or 1
end

---@param filepath   string
---@param line_nr    integer one-indexed line number
---@param annotation string | nil
function M.insert_waypoint(filepath, line_nr, annotation)
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
    extmark_id = extmark_id,
    filepath = filepath,
    indent = 0,
    annotation = annotation,
    linenr = line_nr,
    bufnr = bufnr,
    text = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, true)[1],
    error = nil,
  }

  if not state.wpi then
    state.waypoints = {waypoint}
    state.wpi = 1
  elseif state.wpi == #state.waypoints then
    state.wpi = state.wpi + 1
    state.waypoints[state.wpi] = waypoint
  else
    ---@type waypoint.Waypoint[]
    local new_waypoints = {}
    state.wpi = state.wpi + 1
    for i = 1,state.wpi do
      new_waypoints[i] = state.waypoints[i]
    end
    new_waypoints[state.wpi] = waypoint
    for i = state.wpi+1,#state.waypoints do
      new_waypoints[i] = state.waypoints[i]
    end
    state.waypoints = new_waypoints
  end

  local undo_msg = "Inserted waypoint at position " .. tostring(state.wpi)
  local redo_msg = "Removed waypoint at position" .. tostring(state.wpi)

  undo.save_state(undo_msg, redo_msg)
  M.make_sorted_waypoints()
end

function M.append_waypoint_wrapper()
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  M.append_waypoint(filepath, cur_line_nr, nil)
end

function M.insert_waypoint_wrapper()
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  M.insert_waypoint(filepath, cur_line_nr, nil)
end

function M.append_annotated_waypoint()
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  local annotation = vim.fn.input("Enter annotation for waypoint: ")
  M.append_waypoint(filepath, cur_line_nr, annotation)
end

function M.insert_annotated_waypoint()
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  local annotation = vim.fn.input("Enter annotation for waypoint: ")
  M.insert_waypoint(filepath, cur_line_nr, annotation)
end


function M.reset_current_indent()
  if state.wpi then
    local waypoints
    if state.sort_by_file_and_line then
      waypoints = state.sorted_waypoints
    else
      waypoints = state.waypoints
    end
    waypoints[state.wpi].indent = 0
  end
end

function M.reset_all_indent()
  for _,waypoint in pairs(state.waypoints) do
    waypoint.indent = 0
  end
end

--- @param filepath string the path of the file to find the waypoint in
--- @param linenr integer the one-indexed line number to look for the waypoint on
--- @return integer the one-indexed index of the waypoint if found, or -1 if not
function M.find_waypoint(filepath, linenr)
  local bufnr = vim.fn.bufnr(filepath)
  for i, waypoint in ipairs(state.waypoints) do
    if waypoint.filepath == filepath and waypoint.extmark_id ~= -1 then
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

  local existing_waypoint
  if state.sort_by_file_and_line then
    existing_waypoint = state.sorted_waypoints[existing_waypoint_i]
  else
    existing_waypoint = state.waypoints[existing_waypoint_i]
  end

  if existing_waypoint.extmark_id ~= -1 then
    vim.api.nvim_buf_del_extmark(bufnr, constants.ns, existing_waypoint.extmark_id)
  end

  --- @type waypoint.Waypoint[]
  local waypoints_new = {}
  for _, waypoint in pairs(state.waypoints) do
    if waypoint ~= existing_waypoint then
      table.insert(waypoints_new, waypoint)
    end
  end
  state.waypoints = waypoints_new

  M.make_sorted_waypoints()
end

function M.toggle_waypoint()
  if not u.is_file_buffer() then return end

  --- @type string
  local filepath = vim.fn.expand("%")

  --- @type integer
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)

  --- @type integer
  local existing_waypoint_i = M.find_waypoint(filepath, cur_line_nr)

  if existing_waypoint_i == -1 then
    M.append_waypoint(filepath, cur_line_nr)
  else
    M.remove_waypoint(existing_waypoint_i, filepath)
  end
end

function M.move_waypoint_up()
  local should_return = (
    #state.waypoints <= 1
    or (state.wpi == 1)
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    message.notify(message.sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  local old_wpi = state.wpi

  for _=1, vim.v.count1 do
    local temp = state.waypoints[state.wpi - 1]
    state.waypoints[state.wpi - 1] = state.waypoints[state.wpi]
    state.waypoints[state.wpi] = temp
    state.wpi = state.wpi - 1
  end

  local undo_msg = "Moved waypoint " .. tostring(state.wpi) .. " to position " .. old_wpi
  local redo_msg = "Moved waypoint " .. tostring(old_wpi) .. " to position " .. state.wpi

  undo.save_state(undo_msg, redo_msg)
  M.make_sorted_waypoints()
end

function M.move_waypoint_down()
  local should_return = (
    #state.waypoints <= 1
    or (state.wpi == #state.waypoints)
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    message.notify(message.sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  local old_wpi = state.wpi

  for _=1, vim.v.count1 do
    local temp = state.waypoints[state.wpi + 1]
    state.waypoints[state.wpi + 1] = state.waypoints[state.wpi]
    state.waypoints[state.wpi] = temp
    state.wpi = state.wpi + 1
  end

  local undo_msg = "Moved waypoint " .. tostring(state.wpi) .. " to position " .. old_wpi
  local redo_msg = "Moved waypoint " .. tostring(old_wpi) .. " to position " .. state.wpi

  undo.save_state(undo_msg, redo_msg)
  M.make_sorted_waypoints()
end

function M.move_waypoint_to_top()
  local should_return = (
    #state.waypoints <= 2
    or state.wpi == 1
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    message.notify(message.sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  local temp = state.waypoints[state.wpi]
  for i=state.wpi, 2, -1 do
    state.waypoints[i] = state.waypoints[i-1]
  end
  state.waypoints[1] = temp
  state.wpi = 1
end

function M.move_waypoint_to_bottom()
  local should_return = (
    #state.waypoints <= 2
    or state.wpi == #state.waypoints
    or state.sort_by_file_and_line
  )
  if state.sort_by_file_and_line then
    message.notify(message.sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  local temp = state.waypoints[state.wpi]
  for i=state.wpi, #state.waypoints - 1 do
    state.waypoints[i] = state.waypoints[i+1]
  end
  state.waypoints[#state.waypoints] = temp
  state.wpi = #state.waypoints
end

-- Function to indent or unindent the current line by 2 spaces
function M.indent(increment)
  if state.wpi == nil then return end
  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  for _=1, vim.v.count1 do
    local indent = waypoints[state.wpi].indent + increment
    waypoints[state.wpi].indent = u.clamp(
      indent, 0, constants.max_indent
    )
  end
end

function M.delete_waypoint()
  -- TODO
end

function M.delete_current_waypoint()
  if #state.waypoints == 0 then return end
  M.remove_waypoint(state.wpi, state.waypoints[state.wpi].filepath)
  if #state.waypoints == 0 then
    state.wpi = nil
  else
    state.wpi = u.clamp(state.wpi, 1, #state.waypoints)
  end
end

return M
