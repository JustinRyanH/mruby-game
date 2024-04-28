# TODO

## Current

* Loading Texture Assets
* Texture Assets
* Start Menu
  * Ruby ImUI
* Sounds
## Nice to

* Introduce Better errors for assets
* Debug ImUI
* Collision maybe make Collision list always a set
* Loading `.mrb` code
* Asset Packaging
* WASM build
* Input Recording/Playback
* Particle Emission
* Swap out to use Odin log context

## Done

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

## AOR

### Hot Reload

So the hot reload ended up being cleaner than I thought. That said we will see if I can have the asset

I do wonder if I actually want/need hot reloading for Odin or no. I also wonder if my asset system is going
to pollute my Package/Prod build
