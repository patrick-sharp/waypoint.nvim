local M = {}

---@type waypoint.Test[]
M.tests = {}

---@class waypoint.Test
---@field name string
---@field fn   function
---@field pass boolean | nil
---@field err  unknown

---@param name string
---@param fn   function
function M.describe(name, fn)
  table.insert(M.tests, {
    name = name,
    fn = fn,
    pass = nil,
  })
end

M.file_0 = "lua/waypoint/test/tests/common/file_0.lua"
M.file_1 = "lua/waypoint/test/tests/common/file_1.lua"
M.waypoints_json = "lua/waypoint/test/tests/common/waypoints.json"

return M
