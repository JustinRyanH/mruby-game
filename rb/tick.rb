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

  def tick
    camera.pos, @velocity = spring.motion(camera.pos, velocity, @pos)
  end
end

class EchoBat < GameObject
  def self.create(pos:)
    size = Vector.new(64, 64)

    sprite = Sprite.create(pos:, size:, texture: Textures.copter, tint: Color.black)
    collider = Collider.create(pos:, size:)

    new(collider:, sprite:)
  end

  def tick
    super
    self.pos += Vector.new(200 * FrameInput.delta_time, 0) if FrameInput.key_down?(:d)
    self.pos -= Vector.new(200 * FrameInput.delta_time, 0) if FrameInput.key_down?(:a)
    self.pos -= Vector.new(0, 200 * FrameInput.delta_time) if FrameInput.key_down?(:w)
    self.pos += Vector.new(0, 200 * FrameInput.delta_time) if FrameInput.key_down?(:s)
  end
end

class TestGame
  def initialize
    @started = false
  end

  def tick
    setup unless @started
    @player.tick

    @camera.pos.x = @player.pos.x
    @camera.tick
  end

  def setup
    @started = true
    # size = Vector.new(width, height)
    bg_size = Vector.new(1280, 720) * 2
    Sprite.create(pos: Vector.zero, size: bg_size, texture: Textures.bg0)

    screen = FrameInput.screen
    puts "screen.left: #{screen.left}, screen.right: #{screen.right}, screen.top: #{screen.top}, screen.bottom: #{screen.bottom}"

    create_camera
    create_player
  end

  private

  def create_camera
    offset = FrameInput.screen.size
    offset.x *= 0.25
    offset.y *= 0.5
    @camera = SpringCamera.create(pos: Vector.zero, offset:)
    Camera.current = @camera.camera
  end

  def create_player
    pos = Vector.zero
    @player = EchoBat.create(pos:)
    puts "Player: #{@player}"
  end
end

$game ||= TestGame.new
$game.tick
