# frozen_string_literal: true

require 'assets/scripts/assets'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

$spr ||= Sprite.create(texture: Textures.copter, size: Vector.new(64, 64)).tap do |spr|
  spr.tint = Color.red
end
$spr.pos = Vector.new(400, 600)
$spr.texture = (FrameInput.id % 2).zero? ? Textures.copter : Textures.copter3

# $game ||= Game.new
# $game.tick
