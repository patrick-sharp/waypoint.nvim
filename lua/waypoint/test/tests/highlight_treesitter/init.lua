local test_list = require('waypoint.test.test_list')
local describe = test_list.describe
local file_0 = test_list.file_0

local file = require'waypoint.file'
local u = require("waypoint.util")
local tu = require'waypoint.test.util'
local highlight_treesitter = require'waypoint.highlight_treesitter'

local markdown_file = "lua/waypoint/test/tests/highlight_treesitter/markdown.md"

-- vim.fn.hlID can get id from name. not used in this file, but good to know.

local function buffer_has_ts_parser(bufnr, language)
  local buf_highlighter = vim.treesitter.highlighter.active[bufnr]
  local highlighter_languages = {}
  local has_parser = false
  buf_highlighter.tree:for_each_tree(function(_, tree)
    if language == tree:lang() then
      has_parser = true
    end
    highlighter_languages[#highlighter_languages+1] = tree:lang()
  end)
  return has_parser
end

describe('Highlight treesitter', function()
  assert(u.file_exists(file_0))
  assert(u.file_exists(markdown_file))

  local lua_bufnr = file.open_file(file_0)
  local markdown_bufnr = file.open_file(markdown_file)

  -- treesitter is on by default, this is out of an abundance of caution for previous leftover state
  vim.treesitter.start(lua_bufnr)
  vim.treesitter.start(markdown_bufnr)

  assert(buffer_has_ts_parser(lua_bufnr, "lua"))

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
  tu.assert_has_hl(hlranges[1], "@keyword.function.lua",       1,  8)
  tu.assert_has_hl(hlranges[1], "@variable.lua",              10, 10)
  tu.assert_has_hl(hlranges[1], "@constant.lua",              10, 10)
  tu.assert_has_hl(hlranges[1], "@punctuation.delimiter.lua", 11, 11)
  tu.assert_has_hl(hlranges[1], "@variable.lua",              12, 15)
  tu.assert_has_hl(hlranges[1], "@variable.member.lua",       12, 15)
  tu.assert_has_hl(hlranges[1], "@function.lua",              12, 15)
  tu.assert_has_hl(hlranges[1], "@punctuation.bracket.lua",   16, 16)
  tu.assert_has_hl(hlranges[1], "@punctuation.bracket.lua",   17, 17)

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
  tu.assert_has_hl(hlranges[1], "@variable.lua",             3,  7)
  tu.assert_has_hl(hlranges[1], "@function.call.lua",        3,  7)
  tu.assert_has_hl(hlranges[1], "@function.builtin.lua",     3,  7)
  tu.assert_has_hl(hlranges[1], "@punctuation.bracket.lua",  8,  8)
  tu.assert_has_hl(hlranges[1], "@constant.builtin.lua",     9, 11)
  tu.assert_has_hl(hlranges[1], "@punctuation.bracket.lua", 12, 12)
  tu.assert_has_hl(hlranges[2], "@keyword.return.lua",       3,  8)
  tu.assert_has_hl(hlranges[2], "@constant.builtin.lua",    10, 12)

  -- markdown 
  -- markdown parser might not be installed (e.g. if using the nvim_clean test's init.lua file),
  -- so don't bother testing it if it isn't there.

  if not buffer_has_ts_parser(markdown_bufnr, "markdown") then
    return
  end

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
  tu.assert_has_hl(hlranges[1], "@markup.heading.1.markdown", 0, 11)

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
  tu.assert_has_hl(hlranges[1], "@markup.heading.1.markdown", 0, 11)
  tu.assert_eq(0, #hlranges[2])
  -- for line 3, unformatted text can have whatever highlights it wants, so I don't check
  tu.assert_eq(0, #hlranges[4])
  tu.assert_has_hl(hlranges[5], "@markup.heading.2.markdown", 0, 12)

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
  tu.assert_has_hl(hlranges[1], "@markup.strong.markdown_inline", 1,  8)
  tu.assert_eq(0, #hlranges[2])
  tu.assert_has_hl(hlranges[3], "@markup.raw.block.markdown",     0,  6)
  tu.assert_has_hl(hlranges[3], "@markup.raw.block.markdown",     1,  3)
  tu.assert_has_hl(hlranges[3], "@label.markdown", 4, 6)
  tu.assert_has_hl(hlranges[4], "@markup.raw.block.markdown",     0, 11)
  tu.assert_has_hl(hlranges[4], "@keyword.lua",                   1,  5)
  tu.assert_has_hl(hlranges[4], "@variable.lua",                  7,  7)
  tu.assert_has_hl(hlranges[4], "@operator.lua",                  9,  9)
  tu.assert_has_hl(hlranges[4], "@punctuation.bracket.lua",      11, 11)
  tu.assert_has_hl(hlranges[4], "@constructor.lua",              11, 11)
end)
