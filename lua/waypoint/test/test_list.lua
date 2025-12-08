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

return M
