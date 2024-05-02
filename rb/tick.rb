# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

# This
class StaticObject
  def initialize
    @sprites = []
  end

  def add_sprite(sprite)
    @sprites << sprite
  end
end

class Demo
  def initialize
    @ready = false
  end

  def tick
    setup unless ready?
  end

  def setup
    width, height = FrameInput.screen_size

    @sa = StaticObject.new
    pos = Vector.new(width / 2, height / 2)
    middle = Sprite.create(pos:, size: Vector.all(64), texture: Textures.platform_top_middle)
    left = Sprite.create(pos: pos - Vector.new(64, 0), size: Vector.all(64), texture: Textures.platform_top_left)
    right = Sprite.create(pos: pos + Vector.new(64, 0), size: Vector.all(64), texture: Textures.platform_top_right)
    @sa.add_sprite(middle)
    @sa.add_sprite(left)
    @sa.add_sprite(right)

    @ready = true
  end

  def ready?
    @ready
  end
end

$demo ||= Demo.new
$demo.tick
