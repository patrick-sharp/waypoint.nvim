# Development

What I used for developing this:

## OS

MacOS

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

When not in release mode (see the
[constants.lua](./lua/waypoint/constants.lua) file), waypoint
will create two commands for running tests: `WaypointRunTests`
and `WaypointRunTest`.

To use `WaypointRunTests`, open neovim in the root of the
waypoint.nvim repo and run the command
(`:WaypointRunTests`). This will run all tests, save the
report of which tests passed and failed, and open that report
file in neovim.

To use `WaypointRunTest`, open neovim in the root of the
waypoint.nvim repo and run the command with the name of the
test you want to run. The name of each test is declared in the
test's file. For example, the name of the test in
./lua/test/tests/missing_file is "Missing file". To run that
test, run the command `:WaypointRunTest Missing file`. I use
this to debug individual tests. 

It's less obvious whether the test passed when you run it
individually. Sometimes tests cause errors on purpose, so you
may see errors in your vim messages even for passing tests.
Tests are considered failed if they trigger an assertion error
during execution, so if you don't see any assertion errors it
means the test passed.
