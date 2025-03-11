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
[ ] Bookmarks window automatically resizes when window resizes
[ ] nicer unicode table chars
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
[x] limit horizontal scroll
[ ] look into whether the status line height messes up my window calculations

### ADVANCED FEATURES:
[ ] delete waypoint
[ ] copy waypoint
[ ] paste waypoint
[ ] undo
[ ] redo
[ ] allow cursor to move within a waypoint if you're searching, and for subsequent searches to move between waypoints
