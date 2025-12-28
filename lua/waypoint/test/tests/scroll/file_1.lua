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
  print("Long message with way too many words that will overflow the side of the average viewing window and require horizontal scrolling to see every part of the message. The terminal I was working with was 180 chars wide on a 13 inch laptop, so I think I'll need a lot more than that. One problem I realize the scroll test might pose is that if a screen is wide enough, you wouldn't need to scroll. Maybe I'll just pass the test in that case.")
end

return M
