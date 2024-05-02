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
}.freeze

class TileMapRect
  attr_reader :pos, :width, :height, :size

  def initialize(pos:, width: 3, height: 3, size: 64)
    @pos = pos
    @width = width
    @height = height
    @size = Vector.all(size)
  end

  def build
    [].tap do |out|
      (-1..1).each do |x|
        (-1..1).each do |y|
          offset = Vector.new(x * size.x, y * size.y)
          offset_pos = pos + offset
          out << Sprite.create(pos: offset_pos, size:, texture: SQUARE_MAP[:center])
        end
      end
    end
  end
end

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
  end

  def setup
    width, height = FrameInput.screen_size

    pos = Vector.new(width / 2, height / 2)
    TileMapRect.new(pos:).build
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
