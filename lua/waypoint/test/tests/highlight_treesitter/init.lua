local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0
local file_1 = test_list.file_1

local floating_window = require("waypoint.floating_window")
local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local state = require'waypoint.state'
local uw = require'waypoint.utils_waypoint'
local highlight_treesitter = require'waypoint.highlight_treesitter'

local markdown_file = "lua/waypoint/test/tests/highlight_treesitter/markdown.md"

describe('Highlight treesitter', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(markdown_file))

  local lua_bufnr = file.open_file(file_0)
  local markdown_bufnr = file.open_file(markdown_file)

  ---@type integer
  local start_line
  ---@type integer
  local end_line
  ---@type string[]
  local lines
  ---@type waypoint.HighlightRange[][]
  local hlranges

  start_line = 7
  end_line = 8

  lines = vim.api.nvim_buf_get_lines(lua_bufnr, start_line, end_line, false)
  tu.assert_eq(1, #lines)

  -- hlranges = highlight_treesitter.get_treesitter_syntax_highlights(
  --   lua_bufnr,
  --   lines,
  --   start_line,
  --   end_line
  -- )
  --
  -- for _,x in ipairs(hlranges) do
  --   for _,y in ipairs(x) do
  --     ---@type string | integer
  --     local hl_group = y.hl_group
  --     assert(type(hl_group) == "number")
  --
  --     local name = vim.fn.synIDattr(hl_group, "name")
  --     local hl_info = vim.api.nvim_get_hl(0, {id = hl_group, link = false})
  --     y.hl_info = hl_info
  --     y.name = name
  --   end
  -- end
  --
  -- u.log(hlranges)

  start_line = 1
  end_line = 2

  hlranges = highlight_treesitter.get_treesitter_syntax_highlights(
    markdown_bufnr,
    lines,
    start_line,
    end_line
  )

  for _,x in ipairs(hlranges) do
    for _,y in ipairs(x) do
      ---@type string | integer
      local hl_group = y.hl_group
      assert(type(hl_group) == "number")

      local name = vim.fn.synIDattr(hl_group, "name")
      local hl_info = vim.api.nvim_get_hl(0, {id = hl_group, link = false})
      y.hl_info = hl_info
      y.name = name
    end
  end

  u.log(hlranges)

end)
