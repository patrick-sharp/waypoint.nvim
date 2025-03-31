local M = {}

-- NOTE: The function get_vanilla_syntax_highlights does not work in all
-- circumstances. Syntax rules in vim are usually linked to highlight groups
-- which specify how to color the text that matches the syntax rule. However,
-- some syntax rules have an attribute called "transparent". If a syntax rule
-- is transparent, then it doesn't have a color. If the only syntax rule that
-- matches some text is transparent, the text will be uncolored. Also, multiple
-- syntax rules can have the same id and name as long as they're a different 
-- type of rule (e.g. "match" vs. "region"). Only "region" types can be 
-- transparent. An example of this is the makeSpecTarget rule for Makefiles. 
-- The region is transparent, but the match isn't. This means the text will 
-- only be highlighted if it matches the match, but not if it only matches 
-- the region. While you can use vim.fn.synstack to learn the name/id of the 
-- syntax rule, you can't tell whether it's matching the match or the region. 
-- The code I wrote is a hack that proved to be a heuristic that is always 
-- right for the Makefiles I tried it on, but there could be other situations 
-- that break my code.
-- The heuristic is:
-- if there is only one item in the synstack
-- and that item has a transparent attribute anywhere in its definition
-- then don't show it.
-- This works because with the makefiles I tested on, any text that was 
-- actually supposed to be colored would match both the match and the region, 
-- and so would have two items in the synstack.

local function synname(synid)
  local name = vim.fn.synIDattr(synid, "name")
  return name
end

local function is_syntax_transparent(bufnr, synid)
  local syn_def
  vim.api.nvim_buf_call(bufnr, function()
    syn_def = vim.fn.execute('syntax list ' .. synname(synid))
  end)
  --return syn_def:match("\\btransparent\\b") ~= nil
  return syn_def:match("%s*transparent%s*") ~= nil
end

local function insert_if_not_transparent(bufnr, t, curr)
  if curr == nil then
    return
  end
  local should_insert = not(#curr.synstack == 1 and is_syntax_transparent(bufnr, curr.synstack[1]))
  -- local should_insert = not(#curr.synstack == 1)
  if should_insert then
    curr.synstack = nil
    table.insert(t, curr)
  end
end

local function make_curr(synstack, col)
  return {
    nsid = 0,
    name = synname(synstack[#synstack]),
    synstack = synstack,
    col_start = col,
    col_end = -1,
  }
end

local function synstack_equal(stack_0, stack_1)
  if #stack_0 ~= #stack_1 then
    return false
  end
  for i,group in pairs(stack_0) do
    if group ~= stack_1[i] then
      return false
    end
  end
  return true
end

--- @param bufnr            integer
--- @param lines            table<string>
--- @param start_line_nr_i0 integer
--- @return table<table<HighlightRange>>
function M.get_vanilla_syntax_highlights(bufnr, lines, start_line_nr_i0)
  local hlranges = {}
  for i,line in pairs(lines) do
    local line_hlranges = {}
    local synstack
    vim.api.nvim_buf_call(bufnr, function()
      synstack = vim.fn.synstack(i + start_line_nr_i0, 1)
    end)
    local curr = nil
    if #synstack > 0 then
      curr = make_curr(synstack, 1)
    end
    for col=2,#line do
      vim.api.nvim_buf_call(bufnr, function()
        synstack = vim.fn.synstack(i + start_line_nr_i0, col)
      end)
      if #synstack > 0 then
        if curr then
          if synstack_equal(synstack, curr.synstack) then
            curr.col_end = col
          else
            insert_if_not_transparent(bufnr, line_hlranges, curr)
            curr = make_curr(synstack, col)
          end
        else
          curr = make_curr(synstack, col)
        end
      else
        if curr then
          insert_if_not_transparent(bufnr, line_hlranges, curr)
          curr = nil
        end
      end
    end
    insert_if_not_transparent(bufnr, line_hlranges, curr)
    table.insert(hlranges, line_hlranges)
  end
  return hlranges
end

return M
