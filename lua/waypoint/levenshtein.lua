local M = {}

---@param waypoint waypoint.Waypoint | waypoint.SavedWaypoint
---@param lines string[]
---@return integer
function M.find_best_match(waypoint, lines)
  return 0
end

function M.levenshtein_distance(s1, s2)
  local len1, len2 = #s1, #s2

  -- Early returns for empty strings
  if len1 == 0 then return len2 end
  if len2 == 0 then return len1 end

  -- Create distance matrix
  local matrix = {}
  for i = 0, len1 do
    matrix[i] = {[0] = i}
  end
  for j = 0, len2 do
    matrix[0][j] = j
  end

  -- Fill matrix
  for i = 1, len1 do
    for j = 1, len2 do
      local cost = (s1:sub(i, i) == s2:sub(j, j)) and 0 or 1
      matrix[i][j] = math.min(
        matrix[i-1][j] + 1,      -- deletion
        matrix[i][j-1] + 1,      -- insertion
        matrix[i-1][j-1] + cost  -- substitution
      )
    end
  end

  return matrix[len1][len2]
end

local function compute_distances(t, str)
  local distances = {}
  for i, s in ipairs(t) do
    distances[i] = {
      string = s,
      distance = levenshtein_distance(str, s)
    }
  end
  return distances
end

local function compute_distances_simple(t, str)
  local distances = {}
  for i, s in ipairs(t) do
    distances[i] = levenshtein_distance(str, s)
  end
  return distances
end

return M
