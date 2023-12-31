# Just a Small Square
#### Video Demo: <https://youtu.be/rab_UVigqLw>

### Description:

Just a Small Square is a platforming game made with LOVE2D for Lua. Use the menu
to reset the current level, cycle through previous and next levels, or exit the
game. In each level, navigate your way towards the exit block by combining left
and right movement with jumping, but if you touch the blocks with red-X's, you'll
be sent back to the beginning of the level. Just a Small Square distills the
platforming experience down to a few core controls that are reminiscent of the
classic adventure of a certain, now-illustrious plumber. Your best time for each
level persists for as long as the game is running, so feel free to try other
levels before coming back to try and beat one of your times.

#### To Play: run JASS.exe, found in the game folder.

### Controls:

* **Menu-Toggle**: Tab

* **Menu-Control**: Mouse Left-Click

* **Left / Right**: A / D -or- Left / Right Arrows

* **Jump**: W -or- Up Arrow

### Tips:

* Hold jump to jump higher and float longer.

* Perform a short jump with more hang-time by releasing jump early in your
ascent and quickly re-pressing jump to slow your descent. This is referred to
as a "regrab".

* My personal control preference is to move left and right with WASD while
jumping with Up-Arrow. I find this lowers the mechanical responsibility of my
lateral-movement hand, but really, just do what feels comfortable to you.

### Libaries & Assets:

* Game window scaling is handled by push.

* Objects in this game are colliders, constructed with windfield.

* Level maps are made with Tiled and implemented with Simple Tiled Implementation.

* Platforms and background are recolors of free sprites off itch.io

### Project Layout and thoughts:

**main.lua --** Core game functionality

* My physics implementation admittedly uses few of windfield's features,
relegated to just creating and destroying the objects themselves. At this point,
I feel like I would rather work with LOVE's physics engine sans interfacing.

* There were two major hurdles I faced, regarding the game's physics. The
first was finding a terse method of detecting where the player was colliding with
platforms, as this dictated how the player's movement should be affected or
restricted. It turns out, LOVE has Contact objects that have information on
collisions. In particular, I needed the normal vector X and Y values to detect
the colliding sides. The second hurdle was that LOVE's built-in deltaTime value,
the value that determines state change calculations, is variable. This means
that physics were behaving differently when the frames-per-second changed. To
overcome this, I used a method of overriding love.run() to send a fixed
deltaTime value to love.update() periodically, based on accumulated time lag.
This particular implementation was authored by github user jakebesworth, who
altered a method originally authored by user Leandros.

gist: <https://gist.github.com/jakebesworth/ac09d54cc05690250096f977105a41f8>

**conf.lua --** LOVE2D config file

**assets/GUI_Essential_Free.zip --** Sprite package containing the specific
sprites used in this project

**game/JASS.exe --** Windows executable to run the game

**game/*.dll --** Required LOVE2D dll files to run the game

**libraries/sti/ --** Simple Tiled Implementation library to load and draw game maps

**libraries/windfield/ --** Physics library provides interface for love.physics engine

**libraries/push.lua --** Library for scaling the game resolution to a desired
rendering resolution

**maps/tmx/*.tmx --** tmx files for editing maps in Tiled

**maps/map_*.lua --** Game map files used by STI and windfield to both render
the game maps and create physics objects

**maps/maps.lua --** Table of maps that main.lua should try to load

**sprites/*.png --** A collection of sprites used in this game. Some are free
from itch.io, and some are made by me

### Thanks:

Counting a horrendous Pong-like I made in Scratch at the beginning of CS50x,
this makes my second game ever, so even if you hate it, I'm grateful that you
took the time to check it out.
