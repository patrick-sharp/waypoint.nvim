-- wiki article for type annotations for the lua language server:
-- https://luals.github.io/wiki/annotations

local M = {}

local floating_window = require("waypoint.floating_window")
local crud = require("waypoint.waypoint_crud")
local file = require("waypoint.file")
local constants = require("waypoint.constants")
local config = require("waypoint.config")
local filter = require("waypoint.filter")
local p = require("waypoint.print")


-- binds the keybinding (or keybindings) to the given function 
--- @param keybinding string | string[]
--- @param fn function
local function bind_key(keybinding, fn)
  if type(keybinding) == "string" then
    vim.keymap.set({ 'n', 'v' }, keybinding, fn, { noremap = true })
  elseif type(keybinding) == "table" then
    for i, v in ipairs(keybinding) do
      if type(v) ~= "string" then
        error("Type of element " .. i .. " of keybinding should be string, but was " .. type(v) .. ".")
      end
      vim.keymap.set({ 'n', 'v' }, v, fn, { noremap = true })
    end
  else
    error("Type of param keybinding should be string or table, but was " .. type(keybinding) .. ".")
  end
end

--- @param opts waypoint.ConfigOverride
function M.setup(opts)
  -- set up config

  for k, v in pairs(opts) do
    local default_val = config[k]
    assert(default_val, "property \"" .. k .. "\" does not exist in waypoint config")
    assert(type(v) == type(default_val), "expected the value for property \"" ..  k .. "\" to be of type " .. type(default_val) .. ", but was of type " .. type(v))
    if k == 'keybindings' then
      local keybindings_keys = {
        global_keybindings = true,
        waypoint_window_keybindings = true,
        help_keybindings = true,
      }
      for keybinding_group, keybindings_in_group in pairs(opts.keybindings) do
        assert(keybindings_keys[keybinding_group], "property \"" .. keybinding_group .. "\" does not exist in waypoint config.keybindings")
        for action, keybinding in pairs(keybindings_in_group) do
          local is_string = type(keybinding) == 'string'
          local is_table = type(keybinding) == 'table'
          local is_table_of_strings = is_table
          if is_table then
            for _, keybinding_ in pairs(keybinding) do
              assert(type(keybinding_) == 'string', "keybinding \"" .. keybinding .. "\" for config.keybindings." .. keybinding_group .. "." .. action .. " should be a string, but was of type " .. type(keybinding_) .. ".")
            end
          end
          assert(is_string or is_table_of_strings, "expected the value for config.keybindings." .. keybinding_group .. "." .. action .. " to be a string or table of strings, but was of type " .. type(keybinding) .. ".")
          config.keybindings[keybinding_group][action] = keybinding
        end
      end
    else
      config[k] = v
    end
  end
  vim.api.nvim_create_augroup(constants.augroup, { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = constants.augroup,
    callback = file.load,
    once = true,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = constants.augroup,
    callback = file.save,
    once = true,
  })

  vim.api.nvim_create_autocmd("FilterWritePre", {
    group = constants.augroup,
    callback = filter.save_file_contents,
  })
  vim.api.nvim_create_autocmd("FilterWritePost", {
    group = constants.augroup,
    callback = filter.fix_waypoint_positions,
  })

  bind_key(config.keybindings.global_keybindings.current_waypoint,        floating_window.GoToCurrentWaypoint)
  bind_key(config.keybindings.global_keybindings.prev_waypoint,           floating_window.GoToPrevWaypoint)
  bind_key(config.keybindings.global_keybindings.next_waypoint,           floating_window.GoToNextWaypoint)
  bind_key(config.keybindings.global_keybindings.first_waypoint,          floating_window.GoToFirstWaypoint)
  bind_key(config.keybindings.global_keybindings.last_waypoint,           floating_window.GoToLastWaypoint)
  bind_key(config.keybindings.global_keybindings.prev_neighbor_waypoint,  floating_window.GoToPrevNeighborWaypoint)
  bind_key(config.keybindings.global_keybindings.next_neighbor_waypoint,  floating_window.GoToNextNeighborWaypoint)
  bind_key(config.keybindings.global_keybindings.prev_top_level_waypoint, floating_window.GoToPrevTopLevelWaypoint)
  bind_key(config.keybindings.global_keybindings.next_top_level_waypoint, floating_window.GoToNextTopLevelWaypoint)
  bind_key(config.keybindings.global_keybindings.outer_waypoint,          floating_window.GoToOuterWaypoint)
  bind_key(config.keybindings.global_keybindings.inner_waypoint,          floating_window.GoToInnerWaypoint)
  bind_key(config.keybindings.global_keybindings.open_waypoint_window,    floating_window.open)
  bind_key(config.keybindings.global_keybindings.toggle_waypoint,         crud.toggle_waypoint)
  bind_key('<leader><leader>s', file.save)
  bind_key('<leader><leader>l', file.load)
end

return M
