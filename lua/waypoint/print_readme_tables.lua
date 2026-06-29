local M = {}

local config = require'waypoint.config'
local help = require'waypoint.help_window'
local u = require'waypoint.util'

local kb_header = '| Keybinding | Action |\n| --- | --- |\n'
local config_header = '| Config Field | Value |\n| --- | --- |\n'

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
  local filename = './keybindings.md'
  local file = io.open(filename, "w")
  if not file then
    error("Could not open file for writing")
  end

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

  file:write(table.concat(message))
  file:close()
end

function M.sorted_config()
  local t = config
  local result = {}

  for k, v in pairs(t) do
    if k ~= 'keybindings' then
      table.insert(result, {k, v})
    end
  end

  table.sort(result, function(a, b)
    return tostring(a[1]) < tostring(b[1])
  end)

  return result
end

function M.print_config()
  local filename = 'config.md'
  local file = io.open(filename, "w")
  if not file then
    error("Could not open file for writing")
  end

  ---@type string[]
  local message = {}

  local sorted_config = M.sorted_config()

  message[#message+1] = config_header

  for _, field_value in ipairs(sorted_config) do
    local field = field_value[1]
    local value = field_value[2]

    message[#message+1] = '|`' .. field .. '`|`' .. tostring(value) .. '`|\n'
  end

  file:write(table.concat(message))
  file:close()
end

return M
