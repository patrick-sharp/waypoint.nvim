local test_list = require('waypoint.test.test_list')
local describe = test_list.describe

local levenshtein_distance = require'waypoint.levenshtein'.levenshtein_distance

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
