-- This file contains all methods that modify the waypoints

local M = {}

local constants = require("waypoint.constants")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local message = require("waypoint.message")
local undo = require("waypoint.undo")

M.make_sorted_waypoints = uw.make_sorted_waypoints

---@param filepath   string
---@param line_nr    integer one-indexed line number
---@param annotation string | nil
function M.append_waypoint(filepath, line_nr, annotation)
  if not u.is_file_buffer() then return end
  local bufnr = vim.fn.bufnr(filepath)
  local extmark_id = uw.buf_set_extmark(bufnr, line_nr)

  ---@type waypoint.Waypoint
  local waypoint = {
    has_buffer = true,
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

  local redo_msg = message.append_waypoint(#state.waypoints)
  local undo_msg = message.remove_waypoint(#state.waypoints)

  undo.save_state(undo_msg, redo_msg, #state.waypoints)
  M.make_sorted_waypoints()

  state.wpi = state.wpi or 1
end

---@param filepath   string
---@param line_nr    integer one-indexed line number
---@param annotation string | nil
function M.insert_waypoint(filepath, line_nr, annotation)
  if not u.is_file_buffer() then return end
  local bufnr = vim.fn.bufnr(filepath)
  local extmark_id = uw.buf_set_extmark(bufnr, line_nr)

  ---@type waypoint.Waypoint
  local waypoint = {
    has_buffer = true,
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
    for i = state.wpi,#state.waypoints do
      new_waypoints[i+1] = state.waypoints[i]
    end
    state.waypoints = new_waypoints
  end

  local redo_msg = message.insert_waypoint(state.wpi)
  local undo_msg = message.remove_waypoint(state.wpi)

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

---@param annotation string | nil
function M.append_annotated_waypoint(annotation)
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  if not annotation then
    annotation = vim.fn.input("Enter annotation for waypoint: ")
  end
  M.append_waypoint(filepath, cur_line_nr, annotation)
end

---@param annotation string | nil
function M.insert_annotated_waypoint(annotation)
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  if not annotation then
    annotation = vim.fn.input("Enter annotation for waypoint: ")
  end
  M.insert_waypoint(filepath, cur_line_nr, annotation)
end


function M.reset_current_indent()
  if not state.wpi then
    return
  end

  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  local old_indent = waypoints[state.wpi].indent
  waypoints[state.wpi].indent = 0

  local redo_msg = "Reset indent for waypoint " .. tostring(state.wpi)
  local undo_msg = "Restored waypoint " .. tostring(state.wpi) .. " to indentation of " .. tostring(old_indent)

  undo.save_state(undo_msg, redo_msg)
  M.make_sorted_waypoints()
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
  for i = #state.waypoints, 1, -1 do
    local waypoint = state.waypoints[i]
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

---@param existing_waypoint_i integer
---@param filepath string
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

  local redo_msg = "Deleted waypoint at position " .. tostring(existing_waypoint_i)
  local undo_msg = "Restored waypoint at position " .. tostring(existing_waypoint_i)

  undo.save_state(undo_msg, redo_msg, existing_waypoint_i)
  M.make_sorted_waypoints()
end

function M.remove_waypoints()
  assert(u.is_in_visual_mode())

  ---@type waypoint.Waypoint[]
  local waypoints
  ---@type waypoint.Waypoint[]
  local other_waypoints

  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
    other_waypoints = state.waypoints
  else
    waypoints = state.waypoints
    other_waypoints = state.sorted_waypoints
  end

  ---@type waypoint.Waypoint[]
  local new_waypoints = {}
  ---@type waypoint.Waypoint[]
  local new_other_waypoints = {}

  ---@type table<waypoint.Waypoint, boolean>
  local waypoint_map = {}

  local start_i = math.min(state.wpi, state.vis_wpi)
  local end_i = math.max(state.wpi, state.vis_wpi)

  assert(start_i)
  assert(end_i)

  for i,wp in ipairs(waypoints) do
    if i < start_i or i > end_i then
      new_waypoints[#new_waypoints+1] = wp
      waypoint_map[wp] = true
    else
      if wp.extmark_id ~= -1 then
        vim.api.nvim_buf_del_extmark(wp.bufnr, constants.ns, wp.extmark_id)
      end
    end
  end

  for _,wp in ipairs(other_waypoints) do
    if waypoint_map[wp] then
      new_other_waypoints[#new_other_waypoints+1] = wp
    end
  end

  if state.sort_by_file_and_line then
    state.waypoints = new_other_waypoints
    state.sorted_waypoints = new_waypoints
  else
    state.waypoints = new_waypoints
    state.sorted_waypoints = new_other_waypoints
  end

  local redo_msg = "Deleted waypoints " .. tostring(start_i) .. "-" .. tostring(end_i)
  local undo_msg = "Restored waypoints at positions " .. tostring(start_i) .. "-" .. tostring(end_i)
  state.wpi = start_i

  undo.save_state(undo_msg, redo_msg, start_i)
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

  local redo_msg = message.move_waypoint(old_wpi, state.wpi)
  local undo_msg = message.move_waypoint(state.wpi, old_wpi)

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

  local redo_msg = message.move_waypoint(old_wpi, state.wpi)
  local undo_msg = message.move_waypoint(state.wpi, old_wpi)

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

  local old_wpi = state.wpi

  local temp = state.waypoints[state.wpi]
  for i=state.wpi, 2, -1 do
    state.waypoints[i] = state.waypoints[i-1]
  end
  state.waypoints[1] = temp
  state.wpi = 1

  local redo_msg = message.move_waypoint(old_wpi, state.wpi)
  local undo_msg = message.move_waypoint(state.wpi, old_wpi)

  undo.save_state(undo_msg, redo_msg)
  M.make_sorted_waypoints()
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

  local old_wpi = state.wpi

  local temp = state.waypoints[state.wpi]
  for i=state.wpi, #state.waypoints - 1 do
    state.waypoints[i] = state.waypoints[i+1]
  end
  state.waypoints[#state.waypoints] = temp
  state.wpi = #state.waypoints

  local redo_msg = message.move_waypoint(old_wpi, state.wpi)
  local undo_msg = message.move_waypoint(state.wpi, old_wpi)

  undo.save_state(undo_msg, redo_msg)
  M.make_sorted_waypoints()
end

function M.indent(increment)
  if state.wpi == nil then return end
  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  if u.is_in_visual_mode() then
    local lower = math.min(state.wpi, state.vis_wpi)
    local upper = math.max(state.wpi, state.vis_wpi)
    for i=lower,upper do
      local wp = waypoints[i]
      if uw.should_draw_waypoint(wp) then
        local indent = wp.indent + vim.v.count1 * increment
        wp.indent = u.clamp(
          indent, 0, constants.max_indent
        )
      end
    end
  else
    for _=1, vim.v.count1 do
      local indent = waypoints[state.wpi].indent + increment
      waypoints[state.wpi].indent = u.clamp(
        indent, 0, constants.max_indent
      )
    end
  end

  local redo_msg = "Indented waypoint at position " .. tostring(state.wpi)
  local undo_msg = "Unindented waypoint at position " .. tostring(state.wpi)

  undo.save_state(undo_msg, redo_msg)
  M.make_sorted_waypoints()
end

function M.delete_waypoint()
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  local existing_waypoint_i = M.find_waypoint(filepath, cur_line_nr)
  if existing_waypoint_i == -1 then return end

  M.remove_waypoint(existing_waypoint_i, state.waypoints[existing_waypoint_i].filepath)
end

function M.delete_curr()
  if #state.waypoints == 0 then return end
  ---@type waypoint.Waypoint[]
  local waypoints
  if state.sort_by_file_and_line then
    waypoints = state.sorted_waypoints
  else
    waypoints = state.waypoints
  end
  if u.is_in_visual_mode() then
    M.remove_waypoints()
    state.vis_wpi = nil
  else
    M.remove_waypoint(state.wpi, waypoints[state.wpi].filepath)
  end
  if #state.waypoints == 0 then
    state.wpi = nil
  else
    state.wpi = u.clamp(state.wpi, 1, #state.waypoints)
  end
end

return M
