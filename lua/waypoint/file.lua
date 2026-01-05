-- This file contains functions for saving and loading state from files

local M = {}

local config = require("waypoint.config")
local constants = require("waypoint.constants")
local highlight = require("waypoint.highlight")
local levenshtein   = require "waypoint.levenshtein"
local pretty = require "waypoint.prettyjson"
local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")
local waypoint_crud = require "waypoint.waypoint_crud"
local message = require "waypoint.message"
local undo = require "waypoint.undo"

-- like waypoint.Waypoint, but only a subset of properties that are persisted to a file
---@class waypoint.SavedWaypoint
---@field indent   integer
---@field filepath string used as a backup if the bufnr becomes stale.
---@field text     string | nil
---@field linenr   integer the one-indexed line number the waypoint is on. Can become stale if a buffer edit causes the extmark to move.

local function write_file(path, content)
  local uv = vim.uv or vim.loop  -- Compatibility for different Neovim versions
  local fd = uv.fs_open(path, "w", 438)  -- 438 is decimal for 0666 in octal
  assert(fd)
  local stat = uv.fs_fstat(fd)
  assert(stat)
  vim.uv.fs_write(fd, content, -1)
  uv.fs_close(fd)
end

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

local function encode()
  local state_to_encode = {}
  state_to_encode.wpi = state.wpi
  state_to_encode.waypoints = {}
  state_to_encode.sort_by_file_and_line = state.sort_by_file_and_line
  state_to_encode.show_context = state.show_context
  state_to_encode.show_file_text = state.show_file_text
  state_to_encode.show_full_path = state.show_full_path
  state_to_encode.show_path = state.show_path
  state_to_encode.show_line_num = state.show_line_num
  state_to_encode.context = state.context
  state_to_encode.after_context = state.after_context
  state_to_encode.before_context = state.before_context
  state_to_encode.view = {
    leftcol = state.view.leftcol,
    col = state.view.col
  }
  for _, waypoint in pairs(state.waypoints) do
    local waypoint_to_encode = {}
    local extmark = uw.extmark_from_waypoint(waypoint)
    if extmark then
      waypoint_to_encode.text = waypoint.text
      waypoint_to_encode.indent = waypoint.indent
      waypoint_to_encode.filepath = waypoint.filepath
      waypoint_to_encode.linenr = extmark[1] + 1
      waypoint_to_encode.annotation = waypoint.annotation
    end
    table.insert(state_to_encode.waypoints, waypoint_to_encode)
  end

  local data = pretty(state_to_encode)
  return data
end

function M.save()
  if #state.waypoints == 0 then
    return
  end
  local data = encode()
  write_file(config.file, data)
end

-- loads the buffer (so its text can be accessed) and triggers syntax
-- highlighting for the buffer
local function buffer_init(bufnr)
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
  -- wpi = "number",  -- commenting this out because wpi can be nil
  show_path = "boolean",
  show_full_path = "boolean",
  show_line_num = "boolean",
  show_file_text = "boolean",
  show_context = "boolean",
  after_context = "number",
  before_context = "number",
  context = "number",
  view = {
    -- lnum = "number", -- commenting this out because lnum can be nil
    col = "number",
    leftcol = "number",
  },
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
        "expected value of type ",
        wp_expected, " for key ", tostring(wpk),
        ", but received ", tostring(wpv), "."
      })
      waypoint.extmark_id = -1
      waypoint.linenr = waypoint.linenr or -1
      waypoint.bufnr = -1
      waypoint.filepath = waypoint.filepath or ""
      waypoint.indent = waypoint.indent or 0
      waypoint.annotation = waypoint.annotation or ""
    else
      local bufnr = vim.fn.bufnr(waypoint.filepath)
      if bufnr == -1 and vim.fn.filereadable(waypoint.filepath) ~= 0 then
        bufnr = vim.fn.bufadd(waypoint.filepath)
      end
      waypoint.bufnr = bufnr
      if bufnr ~= -1 then
        buffer_init(bufnr)
        -- one-indexed line number
        local linenr = waypoint.linenr
        local virt_text = nil

        local line_count = vim.api.nvim_buf_line_count(bufnr)

        if linenr <= line_count then
          local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.ns, linenr - 1, -1, {
            id = linenr,
            sign_text = config.mark_char,
            priority = 1,
            sign_hl_group = constants.hl_sign,
            virt_text = virt_text,
            virt_text_pos = "eol",
          })
          waypoint.extmark_id = extmark_id
        else
          waypoint.extmark_id = -1
        end
      else
        waypoint.extmark_id = -1
      end
    end
  end

  highlight.highlight_custom_groups()

  for state_k,state_v in pairs(decoded) do
    state[state_k] = state_v
  end
  waypoint_crud.make_sorted_waypoints()
end

-- this is only called on startup. we want the first entry in the undo history
-- (the earliest state) to be the loaded state, so we call save_state as well here.
function M.load_wrapper()
  M.load_from_file(config.file)
end

---@param file string relative path config file.
function M.load_from_file(file)
  local data = read_file(file)
  if data == nil then
    -- if no waypoints file, then make the first state the empty state
    undo.save_state("", "")
    return
  end

  local decoded = vim.json.decode(data)
  local is_valid, k, v, expected = u.validate(decoded, file_schema, false)
  if not is_valid then
    state.load_error = table.concat({
      "Error loading waypoints from file: expected value of type ",
      expected, " for key ", tostring(k),
      ", but received ", tostring(v), " (of type ", type(v), ")."
    })
    message.notify(state.load_error)
    return
  end

  -- before we load in the waypoints in from a file, delete the current ones.
  for _,waypoint in pairs(state.waypoints) do
    local bufnr = vim.fn.bufnr(waypoint.filepath)
    vim.api.nvim_buf_del_extmark(bufnr, constants.ns, waypoint.extmark_id)
  end

  load_decoded_state_into_state(decoded)
  undo.save_state(message.restored_before_load(file), message.loaded_file(file))
end


---@param bufnr integer
---@param waypoint waypoint.Waypoint | waypoint.SavedWaypoint
---@param linenr integer | nil overrides waypoint linenr if non-nil
local function create_extmark(bufnr, waypoint, linenr)
  -- one-indexed line number
  local extmark_linenr = linenr or waypoint.linenr
  local extmark_id = vim.api.nvim_buf_set_extmark(
    bufnr, constants.ns, extmark_linenr - 1, -1,
    {
      sign_text = config.mark_char,
      priority = 1,
      sign_hl_group = constants.hl_sign,
      virt_text = nil,
      virt_text_pos = "eol",
    }
  )
  return extmark_id
end

-- all waypoints are assumed to be in the same file.
-- mutates the waypoint objects to put them in the new file
---@param src_filepath string
---@param dest_filepath string
---@param waypoints (waypoint.SavedWaypoint | waypoint.Waypoint)[]
---@param change_wpi integer | nil
function M.locate_waypoints_in_file(src_filepath, dest_filepath, waypoints, change_wpi)
  local bufnr = vim.fn.bufnr(dest_filepath)
  ---@type boolean
  if bufnr == -1 then
    local does_file_exist = vim.fn.filereadable(dest_filepath) ~= 0
    if does_file_exist then
      bufnr = vim.fn.bufadd(dest_filepath)
      buffer_init(bufnr)
    else
      message.notify("Error: " .. dest_filepath .. " does not exist")
      for _, waypoint in ipairs(waypoints) do
        waypoint.extmark_id = -1
        waypoint.bufnr      = -1
      end

      return
    end
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(
    bufnr, 0, line_count, true
  )

  -- if a match can't be found for a waypoint, it will have a bufnr of -1 and its original filepath
  for _, waypoint in ipairs(waypoints) do
    local linenr = waypoint.linenr
    waypoint.extmark_id = -1
    waypoint.bufnr      = -1
    if waypoint.text == lines[linenr] then
      if linenr < line_count then
        waypoint.extmark_id = create_extmark(bufnr, waypoint)
      end
      waypoint.linenr = waypoint.linenr
      waypoint.bufnr = bufnr
      waypoint.filepath = dest_filepath
    else
      local new_linenr = levenshtein.find_best_match(waypoint, lines)
      waypoint.filepath = dest_filepath
      if new_linenr == -1 then
        waypoint.error = constants.no_matching_waypoint_error
      else
        waypoint.linenr = new_linenr
        waypoint.bufnr = bufnr
        waypoint.text = lines[new_linenr]
        waypoint.extmark_id = create_extmark(bufnr, waypoint)
      end
    end
  end

  state.wpi = change_wpi

  local undo_msg = message.moved_waypoints_to_file(#waypoints, dest_filepath, src_filepath)
  local redo_msg = message.moved_waypoints_to_file(#waypoints, src_filepath, dest_filepath)

  undo.save_state(undo_msg, redo_msg)
end

return M
