local M = {}

local state = require"waypoint.state"
local uw = require"waypoint.utils_waypoint"

-- sample event
-- {
--   buf = 1,
--   event = "TextChangedI",
--   file = "/Users/patricksharp/repos/bookmarks.nvim/nothing.ts",
--   group = 16,
--   id = 29,
--   match = "/Users/patricksharp/repos/bookmarks.nvim/nothing.ts"
-- }

-- if we deleted the extmark for a waypoint, delete the waypoint
-- if we restored an extmark (e.g. from an undo), then recreate the waypoint
function M.text_changed_callback(opts)
  local bufnr = opts.bufnr
  local deleted_waypoint_idxs = {}
  for i,waypoint in ipairs(state.waypoints) do
    if waypoint.bufnr == bufnr then
      local extmark = uw.extmark_from_waypoint(waypoint)
      if extmark == nil then
        deleted_waypoint_idxs[#deleted_waypoint_idxs+1] = i
      else
        local linenr = extmark[1] + 1 -- convert from zero-indexed to one-indexed
        waypoint.linenr = linenr
      end
    end
  end

end

return M
