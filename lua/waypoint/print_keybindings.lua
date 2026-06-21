local M = {}

local config = require'waypoint.config'
local help = require'waypoint.help_window'
local u = require'waypoint.util'

local kb_header = '| Keybinding | Action |\n| --- | --- |\n'
local filename = './keybindings.md'

function M.print_keybindings()
  local file = io.open(filename, "w")
  u.log(file)

  ---@type string[]
  local message = {}

  message[#message+1] = '### Global Keybindings\n'
  message[#message+1] = kb_header

  for _,kb in ipairs(help.global_keybindings_description) do
    message[#message+1] = '|' .. config.keybindings.global_keybindings[kb[1]] .. '|' .. kb[2] .. '|\n'
  end

  if file then
    file:write(table.concat(message))
    file:close()
  else
    print("Could not open file for writing")
  end
end

return M
