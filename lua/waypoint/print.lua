local function p(...)
  local args_table = { n = select('#', ...), ... }
  local inspected = {}
  for i=1, args_table.n do
    table.insert(inspected, vim.inspect(args_table[i]))
  end
  print(table.concat(inspected, " "))
end

return p
