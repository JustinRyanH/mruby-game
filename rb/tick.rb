# frozen_string_literal: true

require 'assets/scripts/assets'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

$spr ||= Sprite.create(texture: Textures.copter, size: Vector.new(64, 64))
puts $spr
$spr.pos = Vector.new(400, 600)

# $game ||= Game.new
# $game.tick
