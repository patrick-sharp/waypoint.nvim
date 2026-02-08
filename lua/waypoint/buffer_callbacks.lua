-- Callbacks for converting waypoints between buffer and bufferless.
-- When a buffer waypoint's buffer is deleted, we have to save it's linenr,
-- file path, and line text. 
-- When a bufferless waypoint's file is loaded into a buffer, we use the
-- linenr, file path, and line text to locate it. Then we set an extmark for it
-- and save its bufnr.

-- example event:
-- {
--  buf = 3,
--  event = "BufDelete",
--  file = "lua/waypoint/test/tests/common/file_0.lua",
--  group = 15,
--  id = 28,
--  match = "/Users/patricksharp/repos/waypoint.nvim/lua/waypoint/test/tests/common/file_0.lua"
--}

local M = {}

local state = require("waypoint.state")
local u = require("waypoint.utils")
local uw = require("waypoint.utils_waypoint")

---@param arg vim.api.keyset.create_autocmd.callback_args
function M.convert_buffer_waypoints_to_bufferless(arg)
  local bufnr = arg.buf
  local filepath = arg.file
  for _,waypoint in ipairs(state.waypoints) do
    if waypoint.bufnr == bufnr then
      local linenr = uw.linenr_from_waypoint(waypoint)
      assert(linenr)
      local line = vim.api.nvim_buf_get_lines(waypoint.bufnr, linenr - 1, linenr, false)[1]
      waypoint.has_buffer = false
      waypoint.extmark_id = nil
      waypoint.bufnr      = nil
      waypoint.text       = line
      waypoint.filepath   = filepath
      waypoint.linenr     = linenr
    end
  end
end

---@param arg vim.api.keyset.create_autocmd.callback_args
function M.convert_bufferless_waypoints_to_buffer(arg)
  local bufnr = arg.buf
  local filepath = u.relative_path(arg.file)
  for _,waypoint in ipairs(state.waypoints) do
    if waypoint.filepath == filepath then
      local ok = uw.wp_set_extmark(waypoint)
      assert(ok)
      waypoint.has_buffer = true
      waypoint.bufnr      = bufnr
      waypoint.text       = nil
      waypoint.filepath   = nil
      waypoint.linenr     = nil
    end
  end
end

return M
