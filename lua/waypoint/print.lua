local constants = require("waypoint.constants")

if constants.debug then
  -- delete the debug file on startup
  os.remove(constants.debug_file)
end

local counter = 0

-- appends the message to the debug file
local function p(...)
  local args_table = { n = select('#', ...), ... }
  local inspected = {}
  counter = counter + 1
  for i=1, args_table.n do
    table.insert(inspected, vim.inspect(args_table[i]))
  end
  table.insert(inspected, "\n")

  local time = os.date("%Y-%m-%d %H:%M:%S")
  local nanos = vim.uv.hrtime()
  local millis = math.floor(nanos % 1e9 / 1e6)
  local message = table.concat({
    "[" .. time .. "." .. millis .. "] Print " .. counter .. ":\n",
    table.concat(inspected, " "), "\n"
  })

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
