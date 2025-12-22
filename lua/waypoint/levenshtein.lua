local M = {}

-- don't consider a line to be a match if the levenshtein distance is greater than 2/3rds of the maximum possible
local distance_threshold_factor = 2.0 / 3.0

---@param waypoint waypoint.Waypoint | waypoint.SavedWaypoint
---@param lines string[]
---@return integer # the line number (1-indexed) of the best matching line for the waypoint
function M.find_best_match(waypoint, lines)
  local best_match = -1
  local best_distance = -1

  for i, s in ipairs(lines) do
    local trimmed_waypoint_text = vim.trim(waypoint.text)
    local trimmed_line = vim.trim(s)
    local distance = M.levenshtein_distance(trimmed_waypoint_text, trimmed_waypoint_text)
    local distance_threshold = math.max(#trimmed_waypoint_text, #trimmed_line) * distance_threshold_factor
    if distance < distance_threshold then
      if best_distance == -1 then
        best_match = i
        best_match = distance
      elseif distance < best_distance then
        best_match = i
        best_distance = distance
      elseif distance == best_distance then
        -- if two lines are both an equally good match, choose the one on the line closer to the original waypoint
        local linenr_diff = math.abs(waypoint.linenr - i)
        local best_linenr_diff = math.abs(waypoint.linenr - best_match)
        if linenr_diff < best_linenr_diff then
          best_match = i
          best_match = distance
        end
      end
    end
  end

  return best_match
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
