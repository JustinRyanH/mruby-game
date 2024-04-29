# Game written in Mruby/Odin

## Mruby Gems

Compile with these GEMs. It is a reduce version of the GBA mruby
build system.

``` ruby
  conf.gem core: 'mruby-metaprog'
  conf.gem core: 'mruby-pack'
  conf.gem core: 'mruby-sprintf'
  conf.gem core: 'mruby-print'
  conf.gem core: 'mruby-math'
  conf.gem core: 'mruby-struct'
  conf.gem core: 'mruby-compar-ext'
  conf.gem core: 'mruby-enum-ext'
  conf.gem core: 'mruby-string-ext'
  conf.gem core: 'mruby-numeric-ext'
  conf.gem core: 'mruby-array-ext'
  conf.gem core: 'mruby-hash-ext'
  conf.gem core: 'mruby-range-ext'
  conf.gem core: 'mruby-proc-ext'
  conf.gem core: 'mruby-symbol-ext'
  conf.gem core: 'mruby-object-ext'
  conf.gem core: 'mruby-objectspace'
  conf.gem core: 'mruby-enumerator'
  conf.gem core: 'mruby-enum-lazy'
  conf.gem core: 'mruby-toplevel-ext'
  conf.gem core: 'mruby-kernel-ext'
  conf.gem core: 'mruby-class-ext'
  conf.gem core: 'mruby-set'
  conf.gem :github => 'JustinRyanH/mruby-forwardable'
```

## How to build

`odin` [installed](https://odin-lang.org/docs/install/)
### Requirements Windows

Visual Studio installed (VS2019-2022
`ruby` installed on system

### Requirements Mac
install xcode `xcode-select --install`
`llvm` installed on system
`ruby` installed on system

### Build

If you have ruby install run `bundle install`

Then you can run `rake build` and then `./mruby-game.exe` for windows or `./mruby-game` for osx

#### Optional
If you need to change `mruby/mruby_compat.c` you need to run 
and run `rake darwin:compat` (osx) or `rake windows:compat`
