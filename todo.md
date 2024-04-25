# TODO


## Discussions

### The Difficulty algorithm
45 is too extreme, so we're going to adjust the distance to be further out if the random angle is over 40 until it is around 35


## Current

* Come up with an algorithm to make sure the more challenging gaps are achievable
* Custom "Game Engine" 'require' gem

## Nice to

* Start Menuy
  * Ruby ImUI
* Introduce Better errors for assets
* Some sort of imgui I can communicate from ruby for debug

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
