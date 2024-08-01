# TODO

## Current

* Fix the Collision Spot
  - Take the Event, and find the closest edge to the given spot and draw it at edge point
* Improve Collision https://x.com/falconerd/status/1813278682678763731
* Echolocation
  - Port my echo-particles to odin code
* Particle Emission
* Figure out why Background color isn't set

## Nice to Have

* Handle how-reload failures elegantly
* UI
  - Use Spring for UI instead
  - Global Style
  - Rotation (Transitions)
  - Scaling/Stretch (Transitions)
  - Divider Element
  - Scrolling
  - NPatch Background
  - Allow Tracking Transitions
  - Disable Buttons
* Game Start Flashier
  - Have all of the elements come onto the screen sft
* add `require_relative`
* Have the character/obstacle loop in world space
* Swap out to use Odin log context
* Implement Debug Tooling
* Fix windows floating point position errors
* Introduce Better errors for assets
* Loading `.mrb` code
* Asset Packaging
* Input Recording/Playback
* Modules?
* Delegate to the Style
* WASM build
* Don't crash on Ruby Failures
* Debug Console/IMGUI

## Juice

* Squash character on "flap"
* Trail behind character

## Gameplay

* Shadows
* High Risk bouns areas
* Movement
  - Flap (High Sound)
  - Glide (straight with slight drop) (No Sound)
  - Dive (Medium Sound)

## Art

* Swap to SVG art (more organic world?)
* Pick a simple tri-color pallete

## Backburner

## Done

* All Draw Commands go to Draw Command Stack
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
  - Better Animation (easing)
  - Scissor, and max size
  - Handle Jump when we are near done of tween
    we have a problem when we're near the end of a tween and we move it again we get a jump
  - Flexbox
  - Transitions Defined in Style
  - Fix: Padding is broken
  - Begins the Game
* Click on Press?
* Implement Spring
* Make the character move, use a camera to follow
* Engine.screen returns a screen object
* Looping Backgrounds
* I set `left=`, ect. on bounds objects
* Sprite has a Paralax Value
* Sprite has a y-index
* Looping Paralax Backgrounds
* Fix: Smart Parallax  Looping
* Texture Packing
  - Fix the texture packing border issue... https://gist.github.com/karl-zylinski/a5f996ef03f46998b9886fb456279e08
* Loading/Unloading and hot reloading shaders
* Draw Background Static Items to the Static Buffer
* Draw Dynamic Regular Buffer
* Make sure that I can still do proper z-index
* Hide/Reveal Enviormnent Debug
  - Create Render Texture

## AOR

### Hot Reload

So the hot reload ended up being cleaner than I thought. That said we will see if I can have the asset

I do wonder if I actually want/need hot reloading for Odin or no. I also wonder if my asset system is going
to pollute my Package/Prod build

#### Known Issue

- Changing a module won't trigger a reload if files that use that Module. Not important enough to address
