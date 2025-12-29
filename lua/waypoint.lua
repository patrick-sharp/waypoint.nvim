-- wiki article for type annotations for the lua language server:
-- https://luals.github.io/wiki/annotations

local M = {}

local floating_window = require("waypoint.floating_window")
local crud = require("waypoint.waypoint_crud")
local file = require("waypoint.file")
local constants = require("waypoint.constants")
local config = require("waypoint.config")
local filter = require("waypoint.filter")
local test = require("waypoint.test")
local global_keybindings = require("waypoint.global_keybindings")
local undo = require("waypoint.undo")

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

  global_keybindings.bind_key(config.keybindings.global_keybindings, "current_waypoint",          floating_window.go_to_current_waypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "prev_waypoint",             floating_window.GoToPrevWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "next_waypoint",             floating_window.GoToNextWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "first_waypoint",            floating_window.GoToFirstWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "last_waypoint",             floating_window.go_to_last_waypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "prev_neighbor_waypoint",    floating_window.GoToPrevNeighborWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "next_neighbor_waypoint",    floating_window.GoToNextNeighborWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "prev_top_level_waypoint",   floating_window.GoToPrevTopLevelWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "next_top_level_waypoint",   floating_window.GoToNextTopLevelWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "outer_waypoint",            floating_window.GoToOuterWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "inner_waypoint",            floating_window.GoToInnerWaypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "open_waypoint_window",      floating_window.open)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "toggle_waypoint",           crud.toggle_waypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "delete_waypoint",           crud.delete_waypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "append_waypoint",           crud.append_waypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "insert_waypoint",           crud.insert_waypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "append_annotated_waypoint", crud.append_annotated_waypoint)
  global_keybindings.bind_key(config.keybindings.global_keybindings, "insert_annotated_waypoint", crud.insert_annotated_waypoint)

  -- these commands should be run from the root directory of this git repo
  if not constants.is_release then
    vim.api.nvim_create_user_command('WaypointRunTests', test.run_tests, {})
    vim.api.nvim_create_user_command('WaypointRunTest', test.run_test, {nargs = 1})
  end

  -- why does vim not allow you specify a command with just 2 args???
  -- I would like to have the syntax be :MoveWaypointsToFile <src> <dest>,
  -- however that gets complicated when file paths have spaces. The autocomplete
  -- in the vim command mode doesn't escape spaces in paths. If I wanted to have
  -- the two-arg syntax, then you would have to separate the file paths by
  -- unescaped spaces and escape whatever spaces may be in your file path.
  -- Unfortunately, if you do that, then anyone moving files with spaces in the
  -- path won't get autocomplete, which is a really bad experience. To avoid
  -- that, I've decided to make the command move the current waypoint's file's
  -- waypoints to the new path.
  -- If someone actually wants to all this programatically, they can use the floating_window.move_waypoints_to_file function directly
  vim.api.nvim_create_user_command(
    'MoveWaypointsToFile',
    floating_window.move_waypoints_to_file_command,
    {nargs = 1}
  )

  undo.save_state("", "")
end

return M
