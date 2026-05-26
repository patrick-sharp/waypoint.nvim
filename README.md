# waypoint.nvim

## What is Waypoint?

`Waypoint.nvim` helps you keep track of locations in a code base.
`Waypoint.nvim` helps you bookmark locations in a code base.
`Waypoint.nvim` helps you bookmark lines of code.

It is resilient to changes to the underlying files
git checkouts
formatters

It allows you to
- nest and rearrange your bookmarks
- view the context around lines of code
    like grep -A -B or -C
- move waypoints between files (to help with renaming)
- name waypoints
- search through waypoints and their context
- 


## Requirements
Neovim >=v0.11.7 built with LuaJIT (check :version).

## Recommended dependencies
* [Telescope](https://github.com/nvim-telescope/telescope.nvim) makes moving waypoints between files easier

## Installation
We recommend pinning to the latest release tag, e.g. using lazy.nvim

```lua
{
  'patrick-sharp/waypoint.nvim',
  version = '*',
  config = function()
    require("waypoint").setup{
      ...
    }
  end
}
```
To see configurable properties, see [config.lua](lua/waypoint/config.lua)

## Usage

- Navigate to a file and add a waypoint with `ma`
- Hit `ms` to show the waypoint window.
- Hit `d` to delete the waypoint you just made.
- Hit `u` to undo the deletion.
- Hit `c` a few times to increase the context shown around the waypoint.
- Hit `C` to decrease the context shown around the waypoint.
- With expanded context, use `/` to search through the waypoint window as if it were any other buffer.
- Navigate to another file and add a few more waypoints with `ma`
- Hit `ms` to show the waypoint window
- Use `J` and `K` to rearrange the waypoints you just made.
- Hit `mc` to edit the name of a waypoint.
- Hit enter to jump to the location of a waypoint.
- Open the waypoint window again with `ms` and hit `g?` to view all keybinds for waypoint.

## Default keymappings (also in waypoint window's help menu)

## Related projects
