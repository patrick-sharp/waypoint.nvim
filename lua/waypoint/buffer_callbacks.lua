-- Callbacks for converting waypoints between buffer and bufferless.
-- When a buffer waypoint's buffer is deleted, we have to save it's linenr,
-- file path, and line text. 
-- When a bufferless waypoint's file is loaded into a buffer, we use the
-- linenr, file path, and line text to locate it. Then we set an extmark for it
-- and save its bufnr.

local M = {}

---@param arg vim.api.keyset.create_autocmd.callback_args
function M.convert_buffer_waypoints_to_bufferless(arg)
  -- p("REMOVE", arg)
end

---@param arg vim.api.keyset.create_autocmd.callback_args
function M.convert_bufferless_waypoints_to_buffer(arg)
  -- p("ADD", arg)
end

return M
