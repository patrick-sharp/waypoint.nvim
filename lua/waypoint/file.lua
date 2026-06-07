-- This file contains functions for saving and loading waypoint state from files

local M = {}

local config = require "waypoint.config"
local constants = require "waypoint.constants"
local draw_cache = require "waypoint.draw_cache"
local highlight = require "waypoint.highlight"
local levenshtein   = require "waypoint.levenshtein"
local state = require "waypoint.state"
local save = require "waypoint.save"
local u = require "waypoint.util"
local uw = require "waypoint.util_waypoint"
local message = require "waypoint.message"
local undo = require "waypoint.undo"

-- like waypoint.Waypoint, but only a subset of properties that are persisted to a file
---@class waypoint.SavedWaypoint
---@field indent   integer
---@field filepath string used as a backup if the bufnr becomes stale.
---@field text     string?
---@field linenr   integer the one-indexed line number the waypoint is on. Can become stale if a buffer edit causes the extmark to move.

local function read_file(path)
  local uv = vim.uv or vim.loop  -- Compatibility for different Neovim versions
  local fd = uv.fs_open(path, "r", 438)  -- 438 is octal 0666
  if fd == nil then return nil end
  local stat = uv.fs_fstat(fd)
  assert(stat)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  assert(data)
  return data
end

-- loads the buffer (so its text can be accessed) and triggers syntax
-- highlighting for the buffer
function M.buffer_init(bufnr)
  vim.fn.bufload(bufnr)
  -- without this, vim won't apply syntax highlighting to the new buffer
  vim.api.nvim_exec_autocmds("BufRead", { buffer = bufnr })
  vim.api.nvim_set_option_value('buflisted', true, {buf = bufnr})

  -- these few lines force treesitter to highlight the buffer even though it's not in an open window
  local buf_highlighter = vim.treesitter.highlighter.active[bufnr]
  if buf_highlighter then
    -- one-indexed
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    -- seems to work with marks even at end of files, so topline must be an
    -- inclusive zero-indexed bound
    -- I figured out this out by looking at these files:
    --   * <your_nvim_install_path>/share/nvim/runtime/lua/vim/treesitter/highlighter.lua
    --   * <your_nvim_install_path>/share/nvim/runtime/lua/vim/treesitter/languagetree.lua
    buf_highlighter.tree:parse({ 0, line_count - 1 })
  end
end

local file_schema = {
  waypoints = "table",
  wpi = u.union_validator({"number", "nil"}),
  show_path = "boolean",
  show_full_path = "boolean",
  show_line_num = "boolean",
  show_waypoint_text = "boolean",
  show_context = "boolean",
  after_context = "number",
  before_context = "number",
  context = "number",
}

local waypoint_schema = {
  linenr = "number",
  filepath = "string",
  indent = "number",
}

---@param decoded waypoint.State
local function load_decoded_state_into_state(decoded)
  for _,waypoint in pairs(decoded.waypoints) do
    local ok, wpk, wpv, wp_expected = u.validate(waypoint, waypoint_schema, false)
    if not ok then
      waypoint.error = table.concat({
        "Expected value of type ",
        wp_expected, " for key ", tostring(wpk),
        ", but received ", tostring(wpv), "."
      })
      waypoint.has_buffer = false
      waypoint.extmark_id = nil
      waypoint.linenr = waypoint.linenr or -1
      waypoint.bufnr = -1
      waypoint.filepath = waypoint.filepath or ""
      waypoint.indent = waypoint.indent or 0
      waypoint.annotation = waypoint.annotation
    else
      if vim.fn.filereadable(waypoint.filepath) ~= 0 then
        local bufnr = vim.fn.bufnr(waypoint.filepath)
        if bufnr == -1 then
          bufnr = vim.fn.bufadd(waypoint.filepath)
          M.buffer_init(bufnr)
        end
        waypoint.bufnr = bufnr
        waypoint.has_buffer = true

        local line_count = vim.api.nvim_buf_line_count(bufnr)

        if waypoint.linenr <= line_count then
          local extmark_id = uw.buf_set_extmark(bufnr, waypoint.linenr, { has_name = not not waypoint.annotation })
          waypoint.extmark_id = extmark_id
        else
          waypoint.extmark_id = -1
        end
        waypoint.filepath = nil
        waypoint.linenr = nil
        waypoint.text = nil
      else
        waypoint.error = message.file_dne(waypoint.filepath)
        waypoint.has_buffer = false
        waypoint.extmark_id = nil
      end
    end
  end

  highlight.highlight_custom_groups()

  for state_k,state_v in pairs(decoded) do
    state[state_k] = state_v
  end
end

-- this is only called on startup. we want the first entry in the undo history
-- (the earliest state) to be the loaded state, so we call save_state as well here.
function M.load_wrapper()
  M.load_from_file(config.file)
end

---@param file string relative path config file.
function M.load_from_file(file)
  draw_cache.invalidate_cache()
  local data = read_file(file)
  if data == nil then
    -- if no waypoints file, then make the first state the empty state.
    -- no need to save to file since we just loaded from file.
    undo.save_state("", "")
    return
  end

  local decoded = vim.json.decode(data)
  local is_valid, k, v, expected = u.validate(decoded, file_schema, false)
  if not is_valid then
    state.load_error = table.concat({
      "Error loading waypoints from file: Expected value of type ",
      expected, " for key ", tostring(k),
      ", but received ", tostring(v), " (of type ", type(v), ")."
    })
    message.notify(state.load_error)
    return
  end

  -- before we load in the waypoints in from a file, hide the current ones.
  -- they can be made visible again if you undo the file load
  for _,waypoint in pairs(state.waypoints) do
    uw.set_wp_extmark_visible(waypoint, false)
  end

  load_decoded_state_into_state(decoded)
  local affected_wpis = {}
  for i = 1, #state.waypoints do
    affected_wpis[i] = i
  end
  M.save_change(message.restored_before_load(file), message.loaded_file(file), nil, affected_wpis)
end

-- save the state in the undo stack and persist the change to a file.
---@param undo_msg string
---@param redo_msg string
---@param change_wpi integer?
---@param affected_wpis waypoint.AffectedWpis?
function M.save_change(undo_msg, redo_msg, change_wpi, affected_wpis)
  state.sorted_waypoints = nil -- every time we make a change, it invalidates the sorted waypoints table
  undo.save_state(undo_msg, redo_msg, change_wpi, affected_wpis)
  save.schedule_save()
end

---@param bufnr integer
---@param waypoint waypoint.Waypoint | waypoint.SavedWaypoint
---@param linenr integer? overrides waypoint linenr if non-nil
local function create_extmark(bufnr, waypoint, linenr)
  -- one-indexed line number
  local extmark_linenr = linenr or waypoint.linenr
  assert(extmark_linenr)
  local extmark_id = uw.buf_set_extmark(bufnr, extmark_linenr, { has_name = not not waypoint.annotation })
  return extmark_id
end

---@param path string
---@return integer bufnr if successful or already open, -1 if error
function M.open_file(path)
  local bufnr = vim.fn.bufnr(path)
  ---@type boolean
  if bufnr == -1 then
    local does_file_exist = vim.fn.filereadable(path) ~= 0
    if does_file_exist then
      bufnr = vim.fn.bufadd(path)
      M.buffer_init(bufnr)
      return bufnr
    else
      return -1
    end
  end
  return bufnr
end

-- all waypoints are assumed to be in the same file.
-- mutates the waypoint objects to put them in the new file
---@param src_filepath string
---@param dest_filepath string
---@param wpis integer[]
---@param change_wpi integer?
function M.locate_waypoints_in_file(src_filepath, dest_filepath, wpis, change_wpi)
  local bufnr = M.open_file(dest_filepath)
  if bufnr == -1 then
    message.notify("Error: " .. dest_filepath .. " does not exist")
    for _, wpi in ipairs(wpis) do
      local waypoint = state.waypoints[wpi]
      waypoint.has_buffer = false
      waypoint.extmark_id = -1
      waypoint.bufnr      = -1
    end

    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(
    bufnr, 0, line_count, true
  )

  -- if a match can't be found for a waypoint, it will have a bufnr of -1 and its original filepath
  for _, wpi in ipairs(wpis) do
    local waypoint = state.waypoints[wpi]
    local linenr = waypoint.linenr
    waypoint.has_buffer = false
    waypoint.extmark_id = -1
    waypoint.bufnr      = -1
    if waypoint.text == lines[linenr] then
      if linenr < line_count then
        waypoint.extmark_id = create_extmark(bufnr, waypoint)
      end
      waypoint.has_buffer = true
      waypoint.linenr = waypoint.linenr
      waypoint.bufnr = bufnr
      waypoint.filepath = dest_filepath
    else
      local new_linenr = levenshtein.find_best_match(waypoint, lines)
      waypoint.filepath = dest_filepath
      if new_linenr == -1 then
        waypoint.error = constants.error_no_matching_waypoint
      else
        waypoint.has_buffer = true
        waypoint.linenr = new_linenr
        waypoint.bufnr = bufnr
        waypoint.text = lines[new_linenr]
        waypoint.extmark_id = create_extmark(bufnr, waypoint)
      end
    end
  end

  state.wpi = change_wpi

  local undo_msg = message.transferred_waypoints_to_file(#wpis, dest_filepath, src_filepath)
  local redo_msg = message.transferred_waypoints_to_file(#wpis, src_filepath, dest_filepath)

  M.save_change(undo_msg, redo_msg, nil, wpis)
end

return M
