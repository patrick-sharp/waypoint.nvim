local M = {}

-- if the lines haven't changed since last draw (e.g. when we scroll), we'll need to reuse the contexts
---@type waypoint.WaypointContext[]?
M.prev_waypoint_contexts = nil
---@type string[]?
M.prev_waypoint_window_lines = nil
-- if the widths haven't changed since last draw (e.g. when we decrease context), we'll need to reuse the widths
---@type integer[]?
M.prev_widths = nil

-- indexed by bufnr, then by line number
---@type table<integer,waypoint.HighlightRange[][]>?
M.highlight_cache = nil

function M.invalidate_cache()
  M.prev_widths = nil
  M.prev_waypoint_contexts = nil
  M.prev_waypoint_window_lines = nil
  M.highlight_cache = nil
end

return M
