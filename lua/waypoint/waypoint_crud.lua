-- This file contains all methods that modify the waypoints

local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local file = require("waypoint.file")
local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local message = require("waypoint.message")
local undo = require("waypoint.undo")

M.was_most_recent_change_saved = false

-- save the state in the undo stack and persist the change to a file
---@param undo_msg string
---@param redo_msg string
---@param change_wpi integer?
---@param affected_wpis integer[]?
function M.save_change(undo_msg, redo_msg, change_wpi, affected_wpis)
  M.was_most_recent_change_saved = false
  undo.save_state(undo_msg, redo_msg, change_wpi, affected_wpis)
  uw.make_sorted_waypoints()

  -- asynchronously schedule saving to file to not block user interaction
  vim.schedule(function()
    if M.was_most_recent_change_saved then
      return
    end
    file.save()
    M.was_most_recent_change_saved = true
  end)
end

---@param filepath   string
---@param line_nr    integer one-indexed line number
---@param annotation string?
function M.append_waypoint(filepath, line_nr, annotation)
  if not u.is_file_buffer() then return end
  local bufnr = vim.fn.bufnr(filepath)
  local extmark_id = uw.buf_set_extmark(bufnr, line_nr)

  ---@type waypoint.Waypoint
  local waypoint = {
    has_buffer = true,
    extmark_id = extmark_id,
    indent = 0,
    annotation = annotation,
    bufnr = bufnr,
    error = nil,
  }

  table.insert(state.waypoints, waypoint)

  local redo_msg = message.append_waypoint(#state.waypoints)
  local undo_msg = message.remove_waypoint(#state.waypoints)

  undo.save_state(undo_msg, redo_msg, #state.waypoints, { #state.waypoints })
  uw.make_sorted_waypoints()

  state.wpi = state.wpi or 1
end

---@param filepath   string
---@param line_nr    integer one-indexed line number
---@param annotation string?
function M.insert_waypoint(filepath, line_nr, annotation)
  if not u.is_file_buffer() then return end
  local bufnr = vim.fn.bufnr(filepath)
  local extmark_id = uw.buf_set_extmark(bufnr, line_nr)

  ---@type waypoint.Waypoint
  local waypoint = {
    has_buffer = true,
    extmark_id = extmark_id,
    indent = 0,
    annotation = annotation,
    bufnr = bufnr,
    error = nil,
  }

  ---@type integer
  local change_wpi

  if not state.wpi then
    state.waypoints = {waypoint}
    state.wpi = 1
    change_wpi = 1
  elseif state.wpi == #state.waypoints then
    state.wpi = state.wpi + 1
    state.waypoints[state.wpi] = waypoint
    change_wpi = #state.waypoints
  else
    ---@type waypoint.Waypoint[]
    local new_waypoints = {}
    state.wpi = state.wpi + 1
    for i = 1,state.wpi do
      new_waypoints[i] = state.waypoints[i]
    end
    new_waypoints[state.wpi] = waypoint
    change_wpi = state.wpi
    for i = state.wpi,#state.waypoints do
      new_waypoints[i+1] = state.waypoints[i]
    end
    state.waypoints = new_waypoints
  end

  local redo_msg = message.insert_waypoint(state.wpi)
  local undo_msg = message.remove_waypoint(state.wpi)

  undo.save_state(undo_msg, redo_msg, change_wpi, { change_wpi })
  uw.make_sorted_waypoints()
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

---@param annotation string?
function M.append_annotated_waypoint(annotation)
  if not u.is_file_buffer() then return end
  local filepath = vim.fn.expand("%")
  local cur_line_nr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  if not annotation then
    annotation = vim.fn.input("Enter annotation for waypoint: ")
  end
  M.append_waypoint(filepath, cur_line_nr, annotation)
end

---@param annotation string?
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
  if u.is_in_visual_mode() then
    local lower = math.min(state.wpi, state.vis_wpi)
    local upper = math.max(state.wpi, state.vis_wpi)
    for i=lower,upper do
      local wp = waypoints[i]
      if uw.should_draw_waypoint(wp) then
        wp.indent = 0
      end
    end
  else
    waypoints[state.wpi].indent = 0
  end

  local old_indent = waypoints[state.wpi].indent
  waypoints[state.wpi].indent = 0

  local redo_msg = "Reset indent for waypoint " .. tostring(state.wpi)
  local undo_msg = "Restored waypoint " .. tostring(state.wpi) .. " to indentation of " .. tostring(old_indent)

  undo.save_state(undo_msg, redo_msg, state.wpi, { state.wpi })
  uw.make_sorted_waypoints()
end

function M.reset_all_indent()
  for _,waypoint in pairs(state.waypoints) do
    if uw.should_draw_waypoint(waypoint) then
      waypoint.indent = 0
    end
  end
end

---@param bufnr integer the path of the file to find the waypoint in
---@param linenr integer the one-indexed line number to look for the waypoint on
---@return integer the one-indexed index of the waypoint if found, or -1 if not
function M.find_waypoint(bufnr, linenr)
  for i = #state.waypoints, 1, -1 do
    local waypoint = state.waypoints[i]
    local is_eligible = u.all({
      waypoint.bufnr == bufnr,
      waypoint.extmark_id ~= -1,
      uw.should_draw_waypoint(waypoint),
    })
    if is_eligible then
      local extmark = uw.buf_get_extmark(bufnr, waypoint.extmark_id)
      if extmark then
        local extmark_row = extmark[1]
        if extmark_row == linenr then
          return i
        end
      end
    end
  end
  return -1
end

---@param existing_waypoint_i integer
function M.remove_waypoint(existing_waypoint_i)
  local existing_waypoint
  if state.sort_by_file_and_line then
    existing_waypoint = state.sorted_waypoints[existing_waypoint_i]
  else
    existing_waypoint = state.waypoints[existing_waypoint_i]
  end

  if existing_waypoint.extmark_id ~= -1 then
    uw.set_wp_extmark_visible(existing_waypoint, false)
  end

  ---@type waypoint.Waypoint[]
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
  uw.make_sorted_waypoints()
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
        uw.set_wp_extmark_visible(wp, false)
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

-- move current waypoint or selection of waypoints
-- -1 for up, 1 for down
---@param direction -1 | 1
function M.move_curr(direction)
  local split = uw.split_by_drawn()
  local drawn = split.drawn

  local old_wpi = split.cursor_i

  local should_return = u.any({
    state.sort_by_file_and_line,
    #drawn < 2,
    direction == -1 and (split.cursor_i == 1 or split.cursor_vis_i == 1),
    direction == 1 and (split.cursor_i == #drawn or split.cursor_vis_i == #drawn),
  })

  if state.sort_by_file_and_line then
    message.notify(message.sorted_mode_err_msg, vim.log.levels.ERROR)
  end
  if should_return then return end

  if u.is_in_visual_mode() then
    local front = split.top
    if direction == 1 then
      front = split.bottom
    end

    local new_front = u.clamp(front + direction * vim.v.count1, 1, #drawn)
    local new_top = u.clamp(split.top + direction * vim.v.count1, 1, #drawn)

    local front_delta = new_front - front

    local selection = {}
    for i = split.top, split.bottom  do
      selection[#selection+1] = drawn[i]
    end

    -- move non-selected waypoints
    for i = new_front, front + direction, -direction do
      drawn[i + #selection * -direction] = drawn[i]
    end

    -- move selection to new location
    for i, wp in ipairs(selection) do
      drawn[new_top + i - 1] = wp
    end

    split.cursor_i = split.cursor_i + front_delta
    if split.cursor_vis_i then
      split.cursor_vis_i = split.cursor_vis_i + front_delta
    end
  else
    local new_cursor_i = u.clamp(split.cursor_i + direction * vim.v.count1, 1, #drawn)
    local temp = drawn[split.cursor_i]
    for i = split.cursor_i, new_cursor_i - direction, direction do
      drawn[i] = drawn[i + direction]
    end
    drawn[new_cursor_i] = temp
    split.cursor_i = new_cursor_i
  end

  uw.recombine_drawn_split(split)

  local redo_msg = message.move_waypoint(old_wpi, state.wpi)
  local undo_msg = message.move_waypoint(state.wpi, old_wpi)

  undo.save_state(undo_msg, redo_msg)
  uw.make_sorted_waypoints()
end

function M.move_waypoint_to_top()
  if state.sort_by_file_and_line then
    message.notify(message.sorted_mode_err_msg, vim.log.levels.ERROR)
    return
  end

  local split = uw.split_by_drawn()
  local drawn = split.drawn

  local old_wpi = split.cursor_i

  local should_return = #drawn <= 2 or split.cursor_i == 1 or split.cursor_vis_i == 1
  if should_return then
    return
  end

  if u.is_in_visual_mode() then
    local selection = {}
    for i = split.top, split.bottom do
      selection[#selection+1] = split.drawn[i]
    end
    for i = split.top - 1, 1, -1 do
      drawn[i + #selection] = drawn[i]
    end
    for i, wp in ipairs(selection) do
      drawn[i] = wp
    end
    if split.cursor_i < split.cursor_vis_i then
      split.cursor_i = 1
      split.cursor_vis_i = #selection
    else
      split.cursor_i = #selection
      split.cursor_vis_i = 1
    end
  else
    local temp = drawn[split.cursor_i]
    for i=split.cursor_i, 2, -1 do
      drawn[i] = drawn[i-1]
    end
    drawn[1] = temp
    split.cursor_i = 1
  end

  uw.recombine_drawn_split(split)

  local redo_msg = message.move_waypoint(old_wpi, state.wpi)
  local undo_msg = message.move_waypoint(state.wpi, old_wpi)
  undo.save_state(undo_msg, redo_msg)
end

function M.move_waypoint_to_bottom()
  if state.sort_by_file_and_line then
    message.notify(message.sorted_mode_err_msg, vim.log.levels.ERROR)
    return
  end

  local split = uw.split_by_drawn()
  local drawn = split.drawn

  local old_wpi = split.cursor_i

  local should_return = #drawn <= 2 or split.cursor_i == #drawn or split.cursor_vis_i == #drawn
  if should_return then
    return
  end

  if u.is_in_visual_mode() then
    local selection = {}
    for i = split.top, split.bottom do
      selection[#selection+1] = split.drawn[i]
    end
    for i = split.bottom + 1, #drawn do
      drawn[i - #selection] = drawn[i]
    end
    for i, wp in ipairs(selection) do
      drawn[#drawn - #selection + i] = wp
    end
    if split.cursor_i < split.cursor_vis_i then
      split.cursor_i = #drawn - #selection + 1
      split.cursor_vis_i = #drawn
    else
      split.cursor_i = #drawn
      split.cursor_vis_i = #drawn - #selection + 1
    end
  else
    local temp = state.waypoints[state.wpi]
    for i=state.wpi, #state.waypoints - 1 do
      state.waypoints[i] = state.waypoints[i+1]
    end
    state.waypoints[#state.waypoints] = temp
    state.wpi = #state.waypoints
  end

  uw.recombine_drawn_split(split)

  local redo_msg = message.move_waypoint(old_wpi, state.wpi)
  local undo_msg = message.move_waypoint(state.wpi, old_wpi)
  undo.save_state(undo_msg, redo_msg)
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
    local top = math.min(state.wpi, state.vis_wpi)
    local bottom = math.max(state.wpi, state.vis_wpi)
    for i=top,bottom do
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
  uw.make_sorted_waypoints()
end

function M.delete_waypoint()
  if not u.is_file_buffer() then return end
  local curr_linenr = vim.api.nvim_win_get_cursor(0)[1] -- Get current line number (one-indexed)
  local existing_waypoint_i = M.find_waypoint(vim.fn.bufnr(), curr_linenr)
  if existing_waypoint_i == -1 then return end

  M.remove_waypoint(existing_waypoint_i)
end

function M.delete_curr()
  if #state.waypoints == 0 then return end
  if u.is_in_visual_mode() then
    M.remove_waypoints()
    state.vis_wpi = nil
  else
    M.remove_waypoint(state.wpi)
  end
  if #state.waypoints == 0 then
    state.wpi = nil
  else
    state.wpi = u.clamp(state.wpi, 1, #state.waypoints)
  end
end

return M
