# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

class SpringCamera
  attr_reader :camera, :velocity, :spring

  attr_accessor :pos

  def self.create(
    pos: Vector.zero,
    offset: Vector.new(*FrameInput.screen_size),
    spring: Spring.new(10, 1)
  )
    camera = Camera.create(pos:, offset:)
    new(camera:, pos:, spring:)
  end

  def initialize(camera:, pos:, spring:)
    @camera = camera
    @pos = pos
    @velocity = Vector.zero
    @spring = spring
  end

  def update
    camera.pos, @velocity = spring.motion(camera.pos, velocity, @pos)
  end
end

class TestGame
  def initialize
    @started = false
  end

  def tick
    setup unless @started
    @camera.pos = @player.pos
    @camera.update
  end

  def setup
    @started = true
    create_camera
    create_player
  end

  private

  def create_camera
    width, height = FrameInput.screen_size
    offset = Vector.new(width / 4, height / 2)
    @camera = SpringCamera.create(pos: Vector.zero, offset:)
    Camera.current = @camera.camera
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
