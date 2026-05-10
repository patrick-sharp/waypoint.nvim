# Alternatives

Here are a few alternatives that also help you keep track of  

## Vim marks

Pros:
- Allow you to keep track of locations in code.
- With plugins like telescope, you can see all the lines of code you have
  marked in one convenient view.
- Instantly jump to arbitrary marks (with waypoint you can only jump to the
  current waypoint).
- Can jump to a mark as part of a vim motion, allowing operations like d'a
  to delete to mark a. With waypoint, you cannot combine jumping to waypoints
  with text editing operations.

Cons:
- Lots of noise. There are many automatically set marks (like ', ", ^, and .),
  which clutters up the list of marks
- Can't manually order marks, making it hard to remember how marks are related
  to each other. I often use waypoint to keep track of operations that happen
  sequentially in an ordered list, and this is not possible with vanilla vim
  marks.
- Marks only exist globally or per-file. If you use per-file marks, you can't
  see or jump to per-file marks in another file. If you use global marks, then
  you will be limited to just 26 marks for all projects you are working on, which
  can be very limiting.
- You can't see the lines of code around a mark, only the line the mark is on.
- No plugin that I know of has syntax highlighting for marked code in a preview
  window.

## tomasky's bookmarks.nvim

[https://github.com/tomasky/bookmarks.nvim]

Pros:
- Allow you to keep track of locations in code.
- Unlike vim marks, you can have as many bookmarks as you want.

Cons:
- Bookmarks exist globally. You can't narrow the list of bookmarks to just
  those in the current project.
- State gets stale quickly. If you alter the code that is bookmarked, it won't
  be updated in the bookmarks view
- Can't see the lines of code around a bookmark, only the line the bookmark is on.
- Can't manually reorder the bookmarks, they are always displayed in a set order.
- No syntax highlighting for bookmarked code in bookmarks view.

## ThePrimeagen's harpoon

Pros:
- Allow you to keep track of locations in code.
- Optimized for one-button navigation between those locations
- Per-project scope for harpoon marks.
- Can Manually reorder harpoon marks.

Cons:
- Limited to 4 marks.
- Can't have multiple marks in same file.
- No preview of marked code or the lines around it.

## Why none of them worked for me

My job often requires me to read through code I've never seen before and make a
change to it. When I first approach a new codebase, I try to understand the
call path for the logic that is relevant to the change I'm trying to make.
Here is an example scenario that takes advantage of features that none of the
previous solutions have.

Let's say I'm working on a web app. The web app has a form with a
date range. There is logic to validate the contents of the form, but there are
gaps. The validation logic checks that the the start and end of the date range
are both non-null. However, it doesn't validate that the start of the range is
before the end of the range. I'm assigned a ticket to add that validation.
Here are some relevant parts of the code that I might want to understand:
- How to navigate to this form.
- Where the state for the start of the date range is managed.
- Where the state for the end of the date range is managed.
- Where the DOM elements that make up the form are specified/rendered.
- The DOM element where the start of the date range is input.
- The DOM element where the end of the date range is input.
- Where the form is submitted.
- The validation logic that runs on the data of the form.

I want to be able to keep track of all of these in a sequential list
representing the order in which the code runs. Maybe I don't care about the DOM
elements for the date inputs at first, but then later want to keep track of
them and move them into the appropriate place in the list. I can do that with
waypoint, but not with any of the other solutions.

With waypoint, I can keep track of these locations and navigate to them easily.
I don't have to remember where they are, and I can see the syntax highlighted
code at each location in one convenient window.

Imagine that I add the validation logic, and now I need to write a playwright
test for this code (If you are not a web programmer: playwright is a testing
tool that runs Chrome in headless mode and allows you to automate what happens
in a browser). The playwright test locates the DOM element for the start date
using a data-testid attribute in one of the parent DOM elements. It's not on
the line of code for the date range itself, but several lines earlier. If you
were to search data-testid in the whole document, you might get a lot of noise.
However, if you open the waypoint window and expand the context a few lines,
you have a dramatically smaller search space.
