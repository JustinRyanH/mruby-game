# TODO

## Current

* Start Menu
  * Ruby ImUI
  * Idea of Focus

* Make the character move, use a camera to follow
* Have the character/obstacle loop in world space

## Nice to

* Swap out to use Odin log context
* Debug ImUI
* Implement Debug Tooling
* Fix windows floating point position errors
* Introduce Better errors for assets
* Loading `.mrb` code
* Asset Packaging
* Input Recording/Playback
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

## AOR

### Hot Reload

So the hot reload ended up being cleaner than I thought. That said we will see if I can have the asset

I do wonder if I actually want/need hot reloading for Odin or no. I also wonder if my asset system is going
to pollute my Package/Prod build
