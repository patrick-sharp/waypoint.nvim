-- This file contains functions designed to preserve the state of waypoints across filters.
-- In vim, a filter is when you filter part (or all) of a file through an external program.
-- For example, you might use the ex command :%!jq to use the jq program to format json.
-- Since this involves the contents of the file changing, waypoint needs to figure out where
-- the waypoints have moved to.

local M = {}

local state = require("waypoint.state")
local uw = require("waypoint.utils_waypoint")

-- before the filter, we save the file contents as a string so we can diff them with the new file contents
---@type string[] | nil
local pre_filter_buf_lines = nil

-- before the filter, we save the waypoint locations so we can put them back in the right place after the filter
---@type (integer|nil)[] | nil
local waypoint_linenrs = nil

---@param a waypoint.Waypoint
---@param b waypoint.Waypoint
local function waypoint_compare(a, b)
  return a.linenr < b.linenr
end

local function get_current_buffer_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

function M.save_file_contents()
  pre_filter_buf_lines = get_current_buffer_lines()
  waypoint_linenrs = {}
  for i, waypoint in ipairs(state.waypoints) do
    waypoint_linenrs[i] = uw.linenr_from_waypoint(waypoint)
  end
end

-- fix the position of waypoint extmarks.
-- After a filter, all extmarks get put on the first line of the file.
-- This is a callback which will fix their positions after a filter.
function M.fix_waypoint_positions()
  assert(pre_filter_buf_lines)
  assert(waypoint_linenrs)

  local post_filter_buf_lines = get_current_buffer_lines()

  local diff = vim.diff(
    table.concat(pre_filter_buf_lines, "\n"),
    table.concat(post_filter_buf_lines, "\n"),
    { result_type='indices', ignore_whitespace=true }
  )
  assert(diff)

  local bufnr = vim.fn.bufnr()
  local buf_waypoints = {}

  for _, waypoint in ipairs(state.waypoints) do
    if waypoint.bufnr == bufnr then
      table.insert(buf_waypoints, waypoint)
    end
  end

  table.sort(buf_waypoints, waypoint_compare)

  local hunk_i = 1
  -- the number of lines that formatted file is longer than the original file
  -- up to this point.
  -- we use this to keep track of where we should put waypoints that are
  -- between hunks in the diff.
  -- a positive number means the formatted file up to this point is more lines,
  -- a negative number means the formatted file up to this point is fewer lines,
  -- zero means the formatted file up to this point is the same number of lines.
  local running_hunk_length_diff = 0

  for _, waypoint in ipairs(buf_waypoints) do
    local waypoint_line = waypoint.linenr

    if #diff < hunk_i then
      waypoint.linenr = waypoint.linenr + running_hunk_length_diff
      uw.set_extmark(waypoint)
    else
      local old_end_line = 0
      local new_end_line = 0

      while old_end_line < waypoint_line do
        if hunk_i > #diff then
          waypoint.linenr = waypoint.linenr + running_hunk_length_diff
          uw.set_extmark(waypoint)
          break
        end
        local hunk = diff[hunk_i]
        -- all of these are 1-indexed line numbers
        -- all end_line variables are inclusive bounds
        local old_start_line = hunk[1]
        local old_num_lines  = hunk[2]
        local new_start_line = hunk[3]
        local new_num_lines  = hunk[4]

        old_end_line = old_start_line + old_num_lines - 1
        new_end_line = new_start_line + new_num_lines - 1

        local is_before_start = waypoint_line < old_start_line
        local is_after_start = old_start_line <= waypoint_line
        local is_before_end = waypoint_line <= old_end_line

        local should_break = false
        if is_before_start then
          waypoint.linenr = waypoint.linenr + running_hunk_length_diff
          uw.set_extmark(waypoint)
          should_break = true
        elseif is_after_start and is_before_end then
          local num_matches_in_old = 0
          local word = pre_filter_buf_lines[waypoint_line]:gmatch('[%w]+')()

          local old_line = old_start_line
          while old_line < waypoint_line do
            local old_line_content = pre_filter_buf_lines[old_line]
            for _, old_line_word in old_line_content:gmatch('[%w]+') do
              if old_line_word == word then
                num_matches_in_old = num_matches_in_old + 1
              end
            end
            old_line = old_line + 1
          end
          num_matches_in_old = num_matches_in_old + 1

          local num_matches_in_new = 0
          -- since the line updates at the beginning of while loop, we need to start one line before.
          -- we need the line to update at the beginning so we can break out of
          -- the inner for loop at the end without updating new_line
          local new_line = new_start_line - 1
          while num_matches_in_new < num_matches_in_old and new_line <= new_end_line do
            new_line = new_line + 1
            local new_line_content = post_filter_buf_lines[new_line]
            for new_line_word in new_line_content:gmatch('[%w]+') do
              if new_line_word == word then
                num_matches_in_new = num_matches_in_new + 1
              end
              if num_matches_in_new == num_matches_in_old then
                break
              end
            end
          end

          waypoint.linenr = new_line
          uw.set_extmark(waypoint, new_line)
          should_break = true
        end

        if should_break then
          break
        else
          hunk_i = hunk_i + 1

          running_hunk_length_diff = (
            running_hunk_length_diff + new_num_lines - old_num_lines
          )
        end
      end
    end
  end

  pre_filter_buf_lines = nil
  waypoint_linenrs = nil
end

return M
