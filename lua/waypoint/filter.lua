-- This file contains functions designed to preserve the state of waypoints across filters.
-- In vim, a filter is when you filter part (or all) of a file through an external program.
-- For example, you might use the ex command :%!jq to use the jq program to format json.
-- Since this involves the contents of the file changing, waypoint needs to figure out where
-- the waypoints have moved to.

local M = {}

local state = require("waypoint.state")
local u = require("waypoint.util")
local uw = require("waypoint.utils_waypoint")

-- before the filter, we save the file contents as a string so we can diff them with the new file contents
---@type string[]?
local pre_filter_buf_lines = nil

---@class waypoint.LineAndWaypoint
---@field line integer
---@field waypoint waypoint.Waypoint

---@type waypoint.LineAndWaypoint[]
local buf_waypoints = {}

---@param a waypoint.LineAndWaypoint
---@param b waypoint.LineAndWaypoint
local function waypoint_compare(a, b)
  return a.line < b.line
end

local function get_current_buffer_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

function M.save_file_contents()
  buf_waypoints = {}
  pre_filter_buf_lines = get_current_buffer_lines()
  local bufnr = vim.fn.bufnr()
  for _, waypoint in ipairs(state.waypoints) do
    if not waypoint.error and waypoint.bufnr == bufnr then
      local line = uw.linenr_from_waypoint(waypoint)
      assert(line)

      buf_waypoints[#buf_waypoints+1] = {
        line = line,
        waypoint = waypoint,
      }
    end
  end
  table.sort(buf_waypoints, waypoint_compare)
end

-- fix the position of waypoint extmarks.
-- After a filter, all extmarks get put on the first line of the file.
-- This is a callback which will fix their positions after a filter.
function M.fix_waypoint_positions()
  assert(pre_filter_buf_lines)

  local post_filter_buf_lines = get_current_buffer_lines()

  local diff = vim.diff(
    table.concat(pre_filter_buf_lines, "\n"),
    table.concat(post_filter_buf_lines, "\n"),
    { result_type='indices', ignore_whitespace=true }
  )
  assert(diff)

  local hunk_i = 1
  -- the number of lines that filtered file is longer than the original file
  -- up to this point.
  -- we use this to keep track of where we should put waypoints that are
  -- between hunks in the diff.
  -- a positive number means the filtered file up to this point is more lines,
  -- a negative number means the filtered file up to this point is fewer lines,
  -- zero means the filtered file up to this point is the same number of lines.
  local running_hunk_length_diff = 0

  for _, line_and_waypoint in ipairs(buf_waypoints) do
    local waypoint_linenr = line_and_waypoint.line
    local waypoint = line_and_waypoint.waypoint
    local linenr = -1
    if #diff < hunk_i then
      linenr = waypoint_linenr + running_hunk_length_diff
      uw.wp_set_extmark(waypoint, linenr)
    else
      local old_end_line = 0
      local new_end_line = 0

      while old_end_line < waypoint_linenr do
        if hunk_i > #diff then
          linenr = waypoint_linenr + running_hunk_length_diff
          uw.wp_set_extmark(waypoint, linenr)
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

        -- where the waypoint is relative to the hunk. e.g. is_before_start is
        -- whether the waypoint's line is before the start of the hunk
        local is_before_start = waypoint_linenr < old_start_line
        local is_after_start = old_start_line <= waypoint_linenr
        local is_before_end = waypoint_linenr <= old_end_line

        local should_break = false
        if is_before_start then
          -- if the waypoint is before the start 
          linenr = waypoint_linenr + running_hunk_length_diff
          uw.wp_set_extmark(waypoint, linenr)
          should_break = true
        elseif is_after_start and is_before_end then
          -- if the waypoint is somewhere in this hunk, we need to find out
          -- where it is within the hunk.
          -- the way I do this is by taking the first word on the line of the
          -- waypoint, and finding what occurrence it is within the old hunk.
          -- Then find that occurrence in the new hunk.
          -- e.g. if the waypoint's line starts with "local", and it's the 4th
          -- occurrence of the word "local" in the old hunk, then the new
          -- location of the waypoint will be at the 4th occurrence of the 
          -- word "local" in the new hunk
          local num_matches_in_old = 0
          local word = pre_filter_buf_lines[waypoint_linenr]:gmatch('[%w]+')()

          local old_line = old_start_line
          while old_line < waypoint_linenr do
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
          -- since the line updates at the beginning of while loop, we need to
          -- start one line before. we need the line to update at the beginning
          -- so we can break out of the inner for loop at the end without
          -- updating new_line.
          -- this also means our bound has to be < instead of <= so on the last iteration it has a maximum of new_end_line
          local new_line = new_start_line - 1
          while num_matches_in_new < num_matches_in_old and new_line < new_end_line do
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

          -- if the filter has changed the file in a way that prevents us from
          -- locating the extmark, don't set it
          if num_matches_in_old == num_matches_in_new then
            linenr = new_line
            uw.wp_set_extmark(waypoint, linenr)
          end
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
end

return M
