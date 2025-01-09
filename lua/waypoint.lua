local M = {}

local function setup(opts)
  print("WAYPOINT IS EXECUTED " .. opts.name)
end


M.setup = setup

return M
