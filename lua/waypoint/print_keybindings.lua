local M = {}

local config = require'waypoint.config'
local help = require'waypoint.help_window'
local u = require'waypoint.util'

local kb_header = '| Keybinding | Action |\n| --- | --- |\n'
local filename = './keybindings.md'

function M.add_rows(message, keybindings_description, config_keybindings)

  message[#message+1] = kb_header

  for _,kb in ipairs(keybindings_description) do
    if type(config_keybindings[kb[1]]) == 'table' then
      local kba = config_keybindings[kb[1]]
      assert(type(kba) == 'table')

      local kbs = {}
      for _,kb_ in ipairs(kba) do
        kbs[#kbs+1] = '`' .. kb_ .. '`'
      end
      message[#message+1] = '|' .. table.concat(kbs, ' or ') .. '|' .. kb[2] .. '|\n'
    else
      message[#message+1] = '|`' .. config_keybindings[kb[1]] .. '`|' .. kb[2] .. '|\n'
    end
  end
end

function M.print_keybindings()
  local file = io.open(filename, "w")
  u.log(file)

  ---@type string[]
  local message = {}

  message[#message+1] = '### Global Keybindings\n\n'

  M.add_rows(message, help.global_keybindings_description, config.keybindings.global_keybindings)

  message[#message+1] = '\n'

  message[#message+1] = '### Waypoint Window Keybindings\n\n'

  M.add_rows(message, help.waypoint_window_keybindings_description, config.keybindings.waypoint_window_keybindings)

  message[#message+1] = '\n'

  message[#message+1] = '### Help Keybindings\n\n'

  M.add_rows(message, help.help_keybindings_description, config.keybindings.help_keybindings)

  if file then
    file:write(table.concat(message))
    file:close()
  else
    print("Could not open file for writing")
  end
end

return M
