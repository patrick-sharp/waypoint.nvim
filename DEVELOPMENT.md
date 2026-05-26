# Development

This file contains information about what I used to develop waypoint.

## OS

MacOS Sonoma 14.7.2

## Neovim version

NVIM v0.11.5 Build type: Release LuaJIT 2.1.1765228720

## Lua language server version

3.15.0

## Lua language server

I developed waypoint on MacOS using neovim and the lua language server.
The language server uses all the annotations that start with
"---@" for static analysis and type checking of the program. It
is very useful. It provides some of the power of the typescript
type checker type checker, and helped me avoid and catch a ton
of bugs.

I installed the lua language server using the homebrew package manager


```sh
brew install lua-language-server
```

I used version 3.15.0

I use nvim-lspconfig.

To configure the lua language server for neovim, I use the
following config. This config allows you to get type checking
for most of the lua functions that are available when running
lua inside of neovim.

```lua
vim.lsp.config('lua_ls', {
  flags = {
    debounce_text_changes = 150,
  },

  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
    }
  }
})

```

## Plugin development

I use the [lazy.nvim](https://github.com/folke/lazy.nvim) plugin manager for neovim.

To develop this project with lazy.nvim, I clone the repo to an
external directory and use lazy to load the plugin from a file
path rather than a github url.

```lua

require("lazy").setup({
  {
    dir = "~/repos/waypoint.nvim",
    config = function()
      require("waypoint").setup{}
    end,
  },
}
```

## Running tests

When not in release mode (see the is_release field in the 
[constants.lua](./lua/waypoint/constants.lua) file), waypoint
will create two commands for running tests: `WaypointRunTests`
and `WaypointRunTest`.

`WaypointRunTests` runs the entire test suite.

To use `WaypointRunTests`, open neovim in the root of the
waypoint.nvim repo and run the command
(`:WaypointRunTests`). This will run all tests, save the
report of which tests passed and failed, and open that report
file in neovim.

`WaypointRunTest` runs a single test from the test suite.

To use `WaypointRunTest`, open neovim in the root of the
waypoint.nvim repo and run the command with the name of the
test you want to run. The name of each test is declared in the
test's file. For example, the name of the test in
./lua/test/tests/missing_file is "Missing file". To run that
test, run the command `:WaypointRunTest Missing file`. I use
this to debug individual tests. 

Keep in mind that somethings are difficult to test from within vim.
For example, testing the VimResized autocmd callback without mocking out the
window size requires resizing your terminal emulator, which can't be triggered
from within vim.

### Running with a clean config

To make sure that waypoint works on a fresh installation of neovim, I also
made a lua file that allows you to run the tests with a clean neovim config.

To run it, start neovim with this command:

```sh
nvim -u lua/waypoint/test/tests/nvim_clean/init.lua
```

And then run `WaypointRunTests`

### Running without stress tests

The stress tests test the performance of waypoint in extreme conditions.
In them, I assert that operations take less than a certain amount of milliseconds.
Unfortunately, they are flaky. Sometimes, operations take longer than expected.
I think this is due to thread scheduling concerns that are outside of my control.
To give a more consistent experience, I also make a command called
`WaypointRunTestsNoStress` that runs all tests except the stress tests.


## Abbreviations used in this codebase

I frequently use the following abbreviations in this codebase:
* wp: waypoint
* wpi: waypoint index, the index of the currently selected waypoint
* bufnr: buffer number
* linenr: line number
* winnr: window number
* ts: treesitter, the language parser library
