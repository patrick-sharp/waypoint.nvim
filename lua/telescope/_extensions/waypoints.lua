-- Most of the code here is taken from bookmarks.nvim's telescope extension.

local has_telescope, telescope = pcall(require, "telescope")

-- require('telescope').load_extension('waypoint')

if not has_telescope then
   error "This feature requires nvim-telescope/telescope.nvim"
end

local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local entry_display = require "telescope.pickers.entry_display"
local conf = require("telescope.config").values
local telescope_utils = require "telescope.utils"
local config = require("waypoint.config")

local uw = require("waypoint.utils_waypoint")
local state = require("waypoint.state")

local function waypoints(opts)
   opts = opts or {}
   local waypoint_list = {}
   for _, wp in pairs(state.waypoints) do
    local waypoint_file_text = uw.get_waypoint_context(wp, 0, 0)
    local linenr = waypoint_file_text.context_start_linenr + 1 -- telescope expects 1-indexed lines
    table.insert(waypoint_list, {
       filename = wp.filepath,
       lnum = tonumber(linenr),
       text = waypoint_file_text.lines[1]
    })
   end
   local display = function(entry)
      local displayer = entry_display.create {
         separator = "▏",
         items = {
            { width = config.telescope_filename_width },
            { width = config.telescope_linenr_width },
            { remaining = true },
         },
      }
      local line_info = { entry.lnum, "TelescopeResultsLineNr" }
      return displayer {
         telescope_utils.path_smart(entry.filename), -- or path_tail
         line_info,
         entry.text:gsub(".* | ", ""),
      }
   end
   pickers.new(opts, {
      prompt_title = "waypoints",
      finder = finders.new_table {
         results = waypoint_list,
         entry_maker = function(entry)
            return {
               valid = true,
               value = entry,
               display = display,
               ordinal = entry.filename .. entry.text,
               filename = entry.filename,
               lnum = entry.lnum,
               col = 1,
               text = entry.text,
            }
         end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = conf.qflist_previewer(opts),
   }):find()
end

return telescope.register_extension { exports = { waypoints = waypoints } }
