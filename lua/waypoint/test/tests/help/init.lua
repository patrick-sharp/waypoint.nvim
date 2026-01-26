local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local global_keybindings = require("waypoint.global_keybindings")
local floating_window = require("waypoint.floating_window")
local config = require("waypoint.config")
local tu = require("waypoint.test.util")
local u = require("waypoint.utils")

---@param t table
---@param s string
local function find_pair(t, s)
  for i,v in ipairs(t) do
    if v[1] == s then
      return i
    end
  end
  return -1
end

describe('Help', function()
  floating_window.open()

  -- assert global keybindings are set properly
  for k,_ in pairs(config.keybindings.global_keybindings) do
    assert(global_keybindings.global_keybindings[k], k .. " is not globally bound")
  end
  for k,_ in pairs(global_keybindings.global_keybindings) do
    assert(config.keybindings.global_keybindings[k], k .. " is globally bound, but does not exist in keybindings table")
  end

  -- assert waypoint window has proper keybindings
  local wp_bufnr = floating_window.get_bufnr()
  for k,_ in pairs(config.keybindings.waypoint_window_keybindings) do
    assert(floating_window.bound_keys[wp_bufnr][k], k .. " is not bound in the waypoint window")
  end
  for k,_ in pairs(floating_window.bound_keys[wp_bufnr]) do
    assert(config.keybindings.waypoint_window_keybindings[k], k .. " is bound in waypoint window, but does not exist in keybindings table")
  end

  -- assert a description exists for every keybinding
  for k,_ in pairs(config.keybindings.global_keybindings) do
    assert(-1 ~= find_pair(floating_window.global_keybindings_description, k), k .. "has no description")
  end
  for k,_ in pairs(config.keybindings.waypoint_window_keybindings) do
    assert(-1 ~= find_pair(floating_window.waypoint_window_keybindings_description, k), k .. "has no description")
  end
  for k,_ in pairs(config.keybindings.help_keybindings) do
    assert(-1 ~= find_pair(floating_window.help_keybindings_description, k), k .. "has no description")
  end

  local global_keybindings_len   = u.len(config.keybindings.global_keybindings)
  local waypoint_keybindings_len = u.len(config.keybindings.waypoint_window_keybindings)
  local help_keybindings_len     = u.len(config.keybindings.help_keybindings)

  tu.assert_eq(global_keybindings_len,   #floating_window.global_keybindings_description)
  tu.assert_eq(waypoint_keybindings_len, #floating_window.waypoint_window_keybindings_description)
  tu.assert_eq(help_keybindings_len,     #floating_window.help_keybindings_description)
end)
