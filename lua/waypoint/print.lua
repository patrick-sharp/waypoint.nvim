local constants = require("waypoint.constants")

-- delete the debug file on startup
os.remove(constants.debug_file)

-- appends the message to the debug file
local function p(...)
  local args_table = { n = select('#', ...), ... }
  local inspected = {}
  for i=1, args_table.n do
    table.insert(inspected, vim.inspect(args_table[i]))
  end
  table.insert(inspected, "\n")

  local message = table.concat(inspected, " ")

  local file = io.open(constants.debug_file, "a")
  if file then
    file:write(message)
    file:close()
  else
    print("Could not open debug file for writing")
  end
end

return p
