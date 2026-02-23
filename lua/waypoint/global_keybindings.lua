local M = {}

---@type table<string, boolean>
M.global_keybindings = {}

-- binds the keybinding (or keybindings) to the given function 
---@param keybindings table<string, waypoint.Keybinding>
---@param action string
---@param fn function
function M.bind_key(keybindings, action, fn)
  if not keybindings[action] then
    error(action .. " is not a key in the provided keybindings table")
  end
  local keybinding = keybindings[action]
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
  M.global_keybindings[action] = true
end

return M
