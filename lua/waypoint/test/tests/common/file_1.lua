local M = {}

local results = {}

function M.fn_0()
  local t = {}
  for i = 2,8 do
    table.insert(t, i)
  end
  return t
end

function M.fn_1()
  table.insert(results, "hello")
end

function M.fn_2()
  table.insert(results, "world")
end

return M
