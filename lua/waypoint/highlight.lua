local u = require("waypoint.utils")

local M = {}

function M.get_syntax_groups_in_current_line()
  local line_num = vim.fn.line('.')
  local line_text = vim.fn.getline(line_num)
  local result = {}

  for col = 1, #line_text do
    local synstack = vim.fn.synstack(line_num, col)
    local groups = {}

    for i = 1, #synstack do
      local synid = synstack[i]
      local name = vim.fn.synIDattr(synid, "name")
      table.insert(groups, name)
    end

    if #groups > 0 then
      result[col] = groups
    end
  end

  return result
end

function M.wa()
  print("WAAAA")
  local highlights = M.get_syntax_groups_in_current_line()
end

function M.ha()
  local synstack = vim.fn.synstack(vim.fn.line('.'), vim.fn.col('.'))
  local groups = {}

  for i = 1, #synstack do
    local synid = synstack[i]
    local name = vim.fn.synIDattr(synid, "name")
    local hlgroup = vim.api.nvim_get_hl(0, {id = synid})
    while hlgroup.link ~= nil do
      name = hlgroup.link
      hlgroup = vim.api.nvim_get_hl(0, {name = name})
    end
    local hex_str = string.format("#%x", hlgroup.fg)
    table.insert(groups, {name, hlgroup, hex_str})
    -- table.insert(groups, {name})
  end
  u.p(groups)
end


return M
