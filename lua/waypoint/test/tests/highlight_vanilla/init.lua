local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0

local file = require'waypoint.file'
local u = require("waypoint.utils")
local tu = require'waypoint.test.util'
local highlight_vanilla = require'waypoint.highlight_vanilla'

local markdown_file = "lua/waypoint/test/tests/highlight_vanilla/markdown.md"

-- vim.fn.hlID can get id from name. not used in this file, but good to know.

describe('Highlight vanilla', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(markdown_file))

  local lua_bufnr = file.open_file(file_0)
  local markdown_bufnr = file.open_file(markdown_file)

  vim.treesitter.stop(lua_bufnr)
  vim.treesitter.stop(markdown_bufnr)

  tu.assert_eq('lua', vim.api.nvim_buf_get_var(lua_bufnr, 'current_syntax'))
  tu.assert_eq('markdown', vim.api.nvim_buf_get_var(markdown_bufnr, 'current_syntax'))

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

  hlranges = highlight_vanilla.get_vanilla_syntax_highlights(
    lua_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  tu.assert_has_hl(hlranges[1], "Function", 1, 8)

  start_line = 8
  end_line = 10

  lines = vim.api.nvim_buf_get_lines(lua_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_vanilla.get_vanilla_syntax_highlights(
    lua_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  tu.assert_has_hl(hlranges[1], "Identifier",  3,  7)
  tu.assert_has_hl(hlranges[1], "Constant",    9, 11)
  tu.assert_has_hl(hlranges[2], "Statement",   3,  8)
  tu.assert_has_hl(hlranges[2], "Constant",   10, 12)

  -- markdown 

  start_line = 1
  end_line = 4

  lines = vim.api.nvim_buf_get_lines(markdown_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_vanilla.get_vanilla_syntax_highlights(
    markdown_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  tu.assert_has_hl(hlranges[1], "markdownHeadingDelimiter", 1,  2)
  tu.assert_has_hl(hlranges[1], "Title",                    3, 11)
  tu.assert_eq(0, #hlranges[2])
  tu.assert_eq(0, #hlranges[3])

  start_line = 1
  end_line = 6

  lines = vim.api.nvim_buf_get_lines(markdown_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_vanilla.get_vanilla_syntax_highlights(
    markdown_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  tu.assert_has_hl(hlranges[1], "markdownHeadingDelimiter", 1,  2)
  tu.assert_has_hl(hlranges[1], "Title",                    3, 11)
  tu.assert_eq(0, #hlranges[2])
  tu.assert_eq(0, #hlranges[3])
  tu.assert_eq(0, #hlranges[4])
  tu.assert_has_hl(hlranges[5], "markdownHeadingDelimiter", 1,  3)
  tu.assert_has_hl(hlranges[1], "Title",                    3, 11)

  start_line = 10
  end_line = 14

  lines = vim.api.nvim_buf_get_lines(markdown_bufnr, start_line - 1, end_line - 1, false)

  hlranges = highlight_vanilla.get_vanilla_syntax_highlights(
    markdown_bufnr,
    lines,
    start_line,
    end_line
  )

  tu.assert_eq(end_line - start_line, #hlranges)
  tu.assert_has_hl(hlranges[1], "markdownBold",          1,  8)
  tu.assert_eq(0, #hlranges[2])
  tu.assert_has_hl(hlranges[3], "markdownCodeDelimiter", 1,  6)
  tu.assert_has_hl(hlranges[4], "markdownCodeBlock",     1, 11)
end)
