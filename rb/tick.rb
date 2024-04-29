# frozen_string_literal: true

# require 'assets/scripts/setup'
require 'assets/scripts/assets'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

class Animation
  attr_reader :textures

  def initialize(textures)
    @textures = textures
    @current = 0
  end

  def update(entity)
    entity.texture = current_frame if entity.texture.nil?
    return false unless should_update?

    @current = (@current + 1) % textures.size
    entity.texture = current_frame
  end

  private

  def current_frame
    textures[@current]
  end

  def should_update?
    (FrameInput.id % 20).zero?
  end
end

class DemoGame
  def initialize
    @ready = false
  end

  def tick
    setup unless ready?

    @animation.update(@ent)
  end

  def ready?
    @ready
  end

  def setup
    width, height = FrameInput.screen_size
    pos = Vector.new(width / 2, height / 2)
    size = Vector.new(64, 64)

    text = [
      Textures.copter,
      Textures.copter3,
    ]

    @animation = Animation.new(text)

    @ent = Entity.create(pos:, size:)
    @animation.update(@ent)

    @ready = true
  end
end

# $game ||= Game.new
# $game.tick

$game ||= DemoGame.new
$game.tick
