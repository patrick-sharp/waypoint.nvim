local constants = require("waypoint.constants")

if constants.debug then
  -- delete the debug file on startup
  os.remove(constants.debug_file)
end

local counter = 0

-- appends the message to the debug file
local function p(...)
  local args_table = { n = select('#', ...), ... }
  local inspected = {"Print " .. counter .. ":\n"}
  counter = counter + 1
  for i=1, args_table.n do
    table.insert(inspected, vim.inspect(args_table[i]))
  end
  table.insert(inspected, "\n")

  local message = table.concat(inspected, " ")

  local file = io.open(constants.debug_file, "a")
  if constants.debug then
    if file then
      file:write(message)
      file:close()
    else
      print("Could not open debug file for writing")
    end
  else
    print(message)
  end
end

return p
