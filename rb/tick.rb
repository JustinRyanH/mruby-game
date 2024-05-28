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
    @camera.pos, @camera_velocity = @spring.motion(@camera.pos, @camera_velocity, @camera_pos)
    @camera_velocity = Vector.new(100, 0) if FrameInput.key_just_pressed?(:d)
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
    @camera = Camera.create
    @camera.pos = @spr.pos
    @camera_pos = @spr.pos
    @camera.offset = Vector.new(width / 2, height / 2)
    @camera_velocity = Vector.zero
    @spring = Spring.new(25, 0.1)
    Camera.current = @camera
  end
end

$game ||= TestGame.new
$game.tick
