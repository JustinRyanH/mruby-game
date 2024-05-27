# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

class TestGame
  def initialize
    @started = false
  end

  def tick
    setup unless @started
  end

  def setup
    @started = true
    width, height = FrameInput.screen_size

    @spr = Sprite.create(
      pos: Vector.zero,
      size: Vector.new(64, 64),
      tint: Color.blunt_violet,
      texture: Textures.copter,
    )
    @camera = Camera.new
    @camera.pos = @spr.pos
    Camera.current = @camera
  end
end

$game ||= TestGame.new
$game.tick
