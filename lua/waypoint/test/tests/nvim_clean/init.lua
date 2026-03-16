-- This file is for manually testing how waypoint works with a fresh config
-- run it from the base directory of the repo like this:
-- nvim -u lua/waypoint/test/tests/nvim_clean/init.lua

-- add this repo's path to the lua module path manually.
package.path = table.concat{
  package.path, ";",
  vim.fn.getcwd(), '/lua/?.lua;', ";",
  vim.fn.getcwd(), '/lua/?/init.lua;',
}

require("waypoint").setup{}
