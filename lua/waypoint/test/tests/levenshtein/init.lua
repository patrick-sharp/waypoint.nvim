local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local tu = require'waypoint.test.util'

local levenshtein = require'waypoint.levenshtein'
local levenshtein_distance = levenshtein.levenshtein_distance
local find_best_match = levenshtein.find_best_match

describe('Levenshtein', function()
  assert(levenshtein_distance("", "") == 0)
  assert(levenshtein_distance("a", "") == 1)
  assert(levenshtein_distance("", "a") == 1)
  assert(levenshtein_distance("a", "a") == 0)
  assert(levenshtein_distance("ab", "b") == 1)
  assert(levenshtein_distance("aaaaabbbbb", "bbbbb") == 5)
  assert(levenshtein_distance("abcde", "bcde") == 1)
  assert(levenshtein_distance("abcdefg", "zzzzz") == 7)
end)


describe('Levenshtein best match', function()
  ---@type waypoint.SavedWaypoint
  local waypoint = {
    text = "aaa",
    linenr = 4,
    filepath = "",
    indent = 0,
    bufnr = -1,
  }
  local lines = {
    "aaaa",
    "bbbb",
    "cccc",
    "dddd",
    "aaaa",
    "eeee",
    "aaaa",
    "ffff",
  }
  tu.assert_eq(5, find_best_match(waypoint, lines))

  waypoint = {
    text = "zzz",
    linenr = 4,
    filepath = "",
    indent = 0,
    bufnr = -1,
  }
  lines = {
    "aaa",
    "bbb",
    "ccc",
    "ddd",
    "aaa",
    "eee",
    "aaa",
    "fff",
  }
  tu.assert_eq(-1, find_best_match(waypoint, lines))
end)
