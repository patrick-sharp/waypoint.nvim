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
  - like grep -A -B or -C
- move waypoints between files (to help with renaming)
- name waypoints
- search through waypoints and their context

TODO: insert video

## Requirements
Neovim >=v0.11.7 built with LuaJIT (check :version).

## Recommended dependencies
* [Telescope](https://github.com/nvim-telescope/telescope.nvim) makes moving waypoints between files easier.
* [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) if you want file-specific icons to be shown in the waypoint window.

## Installation

I recommend installing some optional dependencies, e.g. using lazy.nvim

```lua
{
  'patrick-sharp/waypoint.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require("waypoint").setup{
      ...
    }
  end
}
```

you can also install the plugin with no dependencies

```lua
'patrick-sharp/waypoint.nvim'
```

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

## Default keymappings

TODO

## Default config values

These are defined in [config.lua](lua/waypoint/config.lua)

TODO

## Related projects

- [tomasky/bookmarks.nvim](https://github.com/tomasky/bookmarks.nvim)
- [LintaoAmons/bookmarks.nvim](https://github.com/LintaoAmons/bookmarks.nvim)
- [crusj/bookmarks.nvim](http://github.com/crusj/bookmarks.nvim)
- [heilgar/bookmarks.nvim](https://github.com/heilgar/bookmarks.nvim)
- [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)
- [arrow.nvim](https://neovimcraft.com/plugin/otavioschwanck/arrow.nvim/)
