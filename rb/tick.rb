# frozen_string_literal: true

# require 'assets/scripts/setup'
require 'assets/scripts/assets'
# h = {}
# ObjectSpace.count_objects(h)
# puts h
class DemoGame
  def initialize
    @ready = false
  end

  def tick
    setup unless ready?
    # Do Some sort of basic debug here
  end

  def ready?
    @ready
  end

  def setup
    width, height = FrameInput.screen_size
    pos = Vector.new(width / 2, height / 2)
    size = Vector.new(64, 64)

    Entity.create(pos:, size:, texture: Textures.copter)
    Entity.create(pos: pos + Vector.new(100, -50), size:, texture: Textures.copter2)
    Entity.create(pos: pos + Vector.new(-100, 75), size:, texture: Textures.copter3)

    @ready = true
  end
end

# $game ||= Game.new
# $game.tick

$game ||= DemoGame.new
$game.tick
