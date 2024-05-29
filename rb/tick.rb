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
    create_camera
    create_player
  end

  private

  def create_camera
    width, height = FrameInput.screen_size
    offset = Vector.new(width / 2, height / 2)
    @camera = Camera.create(pos: Vector.zero, offset:)
    Camera.current = @camera
  end

  def create_player
    pos = Vector.zero
    size = Vector.new(64, 64)

    sprite = Sprite.create(pos:, size:, texture: Textures.copter, tint: Color.blunt_violet)
    collider = Collider.create(pos:, size:)

    @player = GameObject.new(collider:, sprite:)
  end
end

$game ||= TestGame.new
$game.tick
