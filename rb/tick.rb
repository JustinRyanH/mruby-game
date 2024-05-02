# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
SQUARE_MAP = {
  center: Textures.platform_middle,
  left: Textures.platform_middle_left,
  right: Textures.platform_middle_right,
  upper_left: Textures.platform_top_left,
  upper_middle: Textures.platform_top_middle,
  upper_right: Textures.platform_top_right,
  bottom_left: Textures.platform_lower_left,
  bottom_middle: Textures.platform_lower_middle,
  bottom_right: Textures.platform_lower_right
}

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
    @position_index = 0
    @positions = %i[
      center
      left
      right
      upper_left
      upper_middle
      upper_right
      bottom_left
      bottom_middle
      bottom_right
    ]
  end

  def tick
    setup unless ready?
    return unless FrameInput.key_was_down?(:space)

    @position_index = (@position_index + 1) % @positions.size
    texture = SQUARE_MAP[current_section]

    @sprite.texture = texture
  end

  def setup
    width, height = FrameInput.screen_size

    pos = Vector.new(width / 2, height / 2)
    size = Vector.all(64)
    texture = SQUARE_MAP[current_section]
    @sprite = Sprite.create(pos:, size:, texture:)
    @ready = true
  end

  def ready?
    @ready
  end

  private

  def current_section
    @positions[@position_index]
  end
end

$demo ||= Demo.new
$demo.tick
