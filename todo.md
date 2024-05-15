# TODO

## Current

* Start Menu
  - Better Animation (easing)
  - Handle Jump when we are near done of tween
  - Scissor, and max size
  - NPatch Background

* Make the character move, use a camera to follow
* Have the character/obstacle loop in world space

## Nice to Have

* Click on Press?
* Swap out to use Odin log context
* Texture Packing
 - Maybe using Ruby scropts
* Debug ImUI
* Implement Debug Tooling
* Fix windows floating point position errors
* Introduce Better errors for assets
* Loading `.mrb` code
* Asset Packaging
* Input Recording/Playback
* Modules?
* Delegate to the Style
* WASM build

## Juice

* Squash character on "flap"
* Trail behind character

## Gameplay

* Shadows
* Echolocation
* High Risk bouns areas
* Movement
  - Flap (High Sound)
  - Glide (straight with slight drop) (No Sound)
  - Dive (Medium Sound)

## Art

* Swap to SVG art (more organic world?)
* Pick a simple tri-color pallete

## Backburner

* Particle Emission

## Done

* Make Obstacle a collection of Sprites
* Seperate Sprites and Collisions
* Do a special entity regristration and free to check we actually clean them up
* Add Collisions
* Recompile libmruby without require
* Have ruby code change entities
* Track Memory Usage
* == for Entity, Vector
* I picked the wrong size for mrb_int, it's actually 64 bit, I need to audit and fix it
* Font Asset System
* Do death animation on collision
* Restart Game After Animation Finishes restart
* Display "You Died Text"
* Track Score
* Add a Draw.line to draw debug lines
* 45 is too extreme, so we're going to adjust the distance to be further out if the random angle is over 40 until it is around 35
* Come up with an algorithm to make sure the more challenging gaps are achievable
* Debug Mode
* Custom "Game Engine" 'require' gem
* Loading Texture Assets
* Texture Assets
* Animation
* Refactor - Extract a sprite system
* Fix Score
* Re-do the Difficulty Calculator to use the edge differences between start of old and beginning of new
* Sounds
* ImUI
* Start Menu
  - Focus for Button (State)
  - Button
  - Hover
  - Active-Click
  - Scissor, and max size
  - Don't perform the "draw" till a ctx draw call
  - Create an update call that performs the lazy actions
  - Handle Position changing mid animation
  - Better Animation with focus change
## AOR

### Hot Reload

So the hot reload ended up being cleaner than I thought. That said we will see if I can have the asset

I do wonder if I actually want/need hot reloading for Odin or no. I also wonder if my asset system is going
to pollute my Package/Prod build
