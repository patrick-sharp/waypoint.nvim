local M = {}

---@type waypoint.Test[]
M.tests = {}

---@class waypoint.Test
---@field name      string
---@field fn        function
---@field pass      boolean?
---@field err       unknown
---@field millis    number duration of test in milliseconds
---@field is_stress boolean? whether this is a "stress test", meaning that it tests performance with large amounts of data. These tests are important for tracking performance, but slow down development, so I like to have the option to run all non-stress tests when I'm working on features.

---@param name      string
---@param fn        function
---@param is_stress boolean?
function M.describe(name, fn, is_stress)
  table.insert(M.tests, {
    name = name,
    fn = fn,
    pass = nil,
    millis = -1.0,
    is_stress = is_stress,
  })
end

M.file_0 = "lua/waypoint/test/tests/common/file_0.lua"
M.file_1 = "lua/waypoint/test/tests/common/file_1.lua"
M.waypoints_json = "lua/waypoint/test/tests/common/waypoints.json"

M.num_waypoints = 3

M.wp_1_lnum = 1
M.wp_2_lnum = 8
M.wp_3_lnum = 9

M.wp_1_text = "local M = {}"
M.wp_2_text = "table.insert(t, i)"
M.wp_3_text = "end"

return M
