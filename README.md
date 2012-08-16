# ShiftIt

## Managing window size and position in OS X

ShiftIt is an application for OSX that allows you to quickly manipulate window position and size using keyboard shortcuts.

This is a fork of a fork of a...  The original [ShiftIt](http://code.google.com/p/shiftit/) by [Aravindkumar Rajendiran](http://ca.linkedin.com/in/aravind88) is no longer under development.  The subsequent fork by [Fikovnik](https://github.com/fikovnik/ShiftIt) has not been updated in a year.  This fork adds some extra functionality (toggling through multiple sizes, shifting between screens, centering on the current screen), and does some extra work to make window sizing a teeny bit more robust.

I don't intend this to become a canonical fork but am happy to maintain it and take pull requests.

License: [GNU General Public License v3](http://www.gnu.org/licenses/gpl.html) (a la ShiftIt's original license)

## Using ShiftIt

To install: grab the binary from the [downloads section](https://github.com/onsi/ShiftIt/downloads).
I've tested ShiftIt on Lion but will make sure all is well with Mountain Lion when I upgrade.

ShiftIt allows you to tile windows using your keyboard:

- Use ⌃⌥⌘ + arrow keys to shift the focused window to the associatd screen edge.  Repeatedly shifting to an edge toggles through different sizes.
- Use ⌃⌥⌘ + M to maximize the focused window.  Hit it again to toggle the window back to its original size (useful for temporarily zooming a window in).
- Use ⌃⌥⌘ + C to center the focused window.  Hit it repeatedly to toggle through different sizes. 
- Use ⌃⌥⌘ + space to throw the focused window over to the next monitor.  Hit it again to cycle through monitors.

The exact behavior of the ⌃⌥⌘ + arrow key shifts depends on the aspect ratio of the current monitor.  If the monitor is wide screen then shifts to the left and right always fill the screen vertically and toggle through 1/2, 1/3 and then 2/3 the width of the screen.  Shifts up and down maintain the current window width while toggling through four heights: full, 2/3, 1/2, and 1/3 height.  For portrait monitors this behavior is reversed.

So, to throw a window to the top-left corner: ⌃⌥⌘ + ←, ⌃⌥⌘ + ↑, ⌃⌥⌘ + ↑.  So many keystrokes you say?  Yes... but I could never remember my keybindings for the corners (so I removed them!).  Besides, something about smashing arrow keys makes me feel like I'm playing a video game.  This is a fine thing.

**Note** this fork of ShiftIt has removed support for repositioning X11 windows.  If you desperately need this to come back post an issue or (better yet) a pull request.

**Also Note** some applications enforce specific size restrictions.  As far as I can tell there is no way to measure these restrictions *before* resizing windows.  In particular: Xcode doesn't like to get too small, so ShiftIt can't toggle Xcode through thirds on small monitors.  Also, Terminal quantizes its sizes to integer rows and columns, so ShiftIt's manipulations of terminal are approximate and there is sometimes a little overlap/gap around the edges.

## Compiling

On Lion you should be able to open up the Xcode project and compile it.

## 3rd Party Frameworks

 * [ShortcutRecorder](http://code.google.com/p/shortcutrecorder/) framework (*New BSD license*) for capturing key bindings during hotkey reconfiguration.
 * [FMT](https://github.com/fikovnik/FMT) framework (*MIT license*) for some utility functions like handling login items, hot keys, etc.

## Release Notes

- v2.1 (8/16/2012)
    - Fixed embarrasing multi-monitor bug
  
- v2.0 (8/6/2012)
    - Better thirds support
    - More robust window sizing
    - General code clean up
    - Rewrite of window tiling code
