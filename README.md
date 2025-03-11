# waypoint.nvim

## TODO:

### MVP:
[x] autosave
[x] autoload
[ ] syntax highlighting for file text
[ ] user configuration
  [ ] keybinds
  [ ] height / width
  [ ] file path

### POLISH:
[x] Bookmarks window automatically resizes when window resizes
[ ] nicer colors / chars
  [x] nicer unicode table chars
  [ ] nicer mark indicator chars
  [ ] color the mark indicator chars
  [ ] color the table chars differently than text
  [ ] color the files
  [ ] color the line numbers
[ ] popup with keybind info when you press g?
[ ] that weird scroll behavior I still can't figure out
[x] the bug when saving and loading
[x] the bug where marks at beginning/end of file don't have gaps
[ ] support for other movement-like keys
  [ ] H/M/L
  [ ] gg/G
  [ ] / and ?
  [ ] <C-d> and <C-u>
  [ ] (possible fix for all of these: keep track of which line is which waypoint, and set waypoint + draw when cursor moves)
[ ] show A/B/C in footer of window
  [ ] limit A + B + C somehow?
  [ ] make footer background equal to window background
[x] limit horizontal scroll
[x] look into whether the status line height messes up my window calculations
[ ] add a way to indicate whether a context is capped because it's at the beginning or end of files

### ADVANCED FEATURES:
[ ] delete waypoint
[ ] copy waypoint
[ ] paste waypoint
[ ] undo
[ ] redo
[ ] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
[ ] telescope for waypoints
[ ] quickfixlist for waypoints
