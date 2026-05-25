local M = {}

local config = require "waypoint.config"
local pretty = require "waypoint.prettyjson"
local state = require "waypoint.state"
local u = require "waypoint.util"
local uw = require "waypoint.util_waypoint"

local function write_file(path, content)
  local uv = vim.uv or vim.loop  -- Compatibility for different Neovim versions
  local fd = uv.fs_open(path, "w", 438)  -- 438 is decimal for 0666 in octal
  assert(fd)
  local stat = uv.fs_fstat(fd)
  assert(stat)
  vim.uv.fs_write(fd, content, -1)
  uv.fs_close(fd)
end

local function encode()
  local state_to_encode = {}
  state_to_encode.wpi = state.wpi
  state_to_encode.waypoints = {}
  state_to_encode.sort_by_file_and_line = state.sort_by_file_and_line
  state_to_encode.show_context = state.show_context
  state_to_encode.show_waypoint_text = state.show_waypoint_text
  state_to_encode.show_full_path = state.show_full_path
  state_to_encode.show_path = state.show_path
  state_to_encode.show_line_num = state.show_line_num
  state_to_encode.context = state.context
  state_to_encode.after_context = state.after_context
  state_to_encode.before_context = state.before_context
  for _, waypoint in pairs(state.waypoints) do
    local waypoint_to_encode = nil
    if waypoint.has_buffer then
      if vim.api.nvim_buf_get_name(waypoint.bufnr) ~= "" and uw.should_draw_waypoint(waypoint) then
        local filepath = uw.filepath_from_waypoint(waypoint)
        local linenr = uw.linenr_from_waypoint(waypoint)
        if linenr then
          local line = vim.api.nvim_buf_get_lines(waypoint.bufnr, linenr - 1, linenr, false)[1]
          waypoint_to_encode = {
            text = line,
            filepath = filepath,
            linenr = linenr,
            indent = waypoint.indent,
            annotation = waypoint.annotation,
          }
        end
      end
    else
      waypoint_to_encode = {
        text = waypoint.text,
        filepath = waypoint.filepath,
        linenr = waypoint.linenr,
        indent = waypoint.indent,
        annotation = waypoint.annotation,
      }
    end

    if waypoint_to_encode then
      table.insert(state_to_encode.waypoints, waypoint_to_encode)
    end
  end

  local data = pretty(state_to_encode)
  return data
end

function M.save()
  if #state.waypoints == 0 then
    -- don't save a file with nothing in it
    if u.file_exists(config.file) then
      os.remove(config.file)
    end
    return
  end
  local data = encode()
  write_file(config.file, data)
end

M.was_most_recent_change_saved = false

function M.schedule_save()
  M.was_most_recent_change_saved = false
  -- asynchronously schedule saving to file to not block user interaction
  vim.schedule(function()
    if M.was_most_recent_change_saved then
      return
    end
    M.save()
    M.was_most_recent_change_saved = true
  end)
end

return M
