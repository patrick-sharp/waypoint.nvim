local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0

local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local highlight_treesitter = require'waypoint.highlight_treesitter'

local markdown_file = "lua/waypoint/test/tests/highlight_treesitter/markdown.md"

-- vim.fn.hlID can get id from name. not used in this file, but good to know.

---@param hlrange waypoint.HighlightRange
---@return string
local function get_hl_name(hlrange)
  local hl_group = hlrange.hl_group
  tu.assert_eq("number", type(hl_group))
  ---@cast hl_group integer
  return vim.fn.synIDattr(hl_group, "name")
end

---@param hlranges waypoint.HighlightRange[]
local function inspect_hlranges(hlranges)
  for _,hlrange in ipairs(hlranges) do
    ---@type string | integer
    local hl_group = hlrange.hl_group
    assert(type(hl_group) == "number")

    local name = vim.fn.synIDattr(hl_group, "name")
    ---@cast hlrange any
    hlrange.name = name
  end
  return vim.inspect(hlranges)
end

---@param hlranges waypoint.HighlightRange[] highlight ranges for a single row
---@param name string
---@param col_start integer
---@param col_end integer
local function assert_has_hl(hlranges, name, col_start, col_end)
  local counter = 0
  for _, hlrange in ipairs(hlranges) do
    local range_name = get_hl_name(hlrange)
    if range_name == name then
      counter = counter + 1
      if col_start == hlrange.col_start and col_end == hlrange.col_end then
        return
      end
    end
  end
  local hlranges_msg = inspect_hlranges(hlranges)
  if counter == 0 then
    error("hlranges has no range with name " .. name .. "\nhlranges = " .. hlranges_msg)
  else
    error("hlranges has " .. counter .. " ranges with name " .. name .. ", but none are over the right columns" .. "\nhlranges = " .. hlranges_msg)
  end
end

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

  -- lua

  start_line = 7
  end_line = 8

  lines = vim.api.nvim_buf_get_lines(lua_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_treesitter.get_treesitter_syntax_highlights(
    lua_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  assert_has_hl(hlranges[1], "@keyword.function.lua",       1,  8)
  assert_has_hl(hlranges[1], "@variable.lua",              10, 10)
  assert_has_hl(hlranges[1], "@constant.lua",              10, 10)
  assert_has_hl(hlranges[1], "@punctuation.delimiter.lua", 11, 11)
  assert_has_hl(hlranges[1], "@variable.lua",              12, 15)
  assert_has_hl(hlranges[1], "@variable.member.lua",       12, 15)
  assert_has_hl(hlranges[1], "@function.lua",              12, 15)
  assert_has_hl(hlranges[1], "@punctuation.bracket.lua",   16, 16)
  assert_has_hl(hlranges[1], "@punctuation.bracket.lua",   17, 17)

  start_line = 8
  end_line = 10

  lines = vim.api.nvim_buf_get_lines(lua_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_treesitter.get_treesitter_syntax_highlights(
    lua_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  assert_has_hl(hlranges[1], "@variable.lua",             3,  7)
  assert_has_hl(hlranges[1], "@function.call.lua",        3,  7)
  assert_has_hl(hlranges[1], "@function.builtin.lua",     3,  7)
  assert_has_hl(hlranges[1], "@punctuation.bracket.lua",  8,  8)
  assert_has_hl(hlranges[1], "@constant.builtin.lua",     9, 11)
  assert_has_hl(hlranges[1], "@punctuation.bracket.lua", 12, 12)
  assert_has_hl(hlranges[2], "@keyword.return.lua",       3,  8)
  assert_has_hl(hlranges[2], "@constant.builtin.lua",    10, 12)

  -- markdown 

  start_line = 1
  end_line = 4

  lines = vim.api.nvim_buf_get_lines(markdown_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_treesitter.get_treesitter_syntax_highlights(
    markdown_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  assert_has_hl(hlranges[1], "@markup.heading.1.markdown", 0, 11)

  start_line = 1
  end_line = 6

  lines = vim.api.nvim_buf_get_lines(markdown_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_treesitter.get_treesitter_syntax_highlights(
    markdown_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  assert_has_hl(hlranges[1], "@markup.heading.1.markdown", 0, 11)
  tu.assert_eq(0, #hlranges[2])
  -- for line 3, unformatted text can have whatever highlights it wants, so I don't check
  tu.assert_eq(0, #hlranges[4])
  assert_has_hl(hlranges[5], "@markup.heading.2.markdown", 0, 12)

  -- this tests that the lua within markdown is highlighted properly
  --
  start_line = 10
  end_line = 14

  lines = vim.api.nvim_buf_get_lines(markdown_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_treesitter.get_treesitter_syntax_highlights(
    markdown_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  assert_has_hl(hlranges[1], "@markup.strong.markdown_inline", 1,  8)
  tu.assert_eq(0, #hlranges[2])
  assert_has_hl(hlranges[3], "@markup.raw.block.markdown",     0,  6)
  assert_has_hl(hlranges[3], "@markup.raw.block.markdown",     1,  3)
  assert_has_hl(hlranges[3], "@label.markdown", 4, 6)
  assert_has_hl(hlranges[4], "@markup.raw.block.markdown",     0, 11)
  assert_has_hl(hlranges[4], "@keyword.lua",                   1,  5)
  assert_has_hl(hlranges[4], "@variable.lua",                  7,  7)
  assert_has_hl(hlranges[4], "@operator.lua",                  9,  9)
  assert_has_hl(hlranges[4], "@punctuation.bracket.lua",      11, 11)
  assert_has_hl(hlranges[4], "@constructor.lua",              11, 11)
end)
