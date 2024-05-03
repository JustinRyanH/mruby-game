# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
SQUARE_MAP = {
  middle_middle: Textures.platform_middle,
  middle_left: Textures.platform_middle_left,
  middle_right: Textures.platform_middle_right,
  upper_left: Textures.platform_top_left,
  upper_middle: Textures.platform_top_middle,
  upper_right: Textures.platform_top_right,
  lower_left: Textures.platform_lower_left,
  lower_middle: Textures.platform_lower_middle,
  lower_right: Textures.platform_lower_right
}.freeze

class SquareMap
  attr_reader :map

  def initialize(map = SQUARE_MAP)
    @map = map
  end

  def get_square(x, y)
    @map[:"#{y}_#{x}"]
  end
end

class TileMapRect
  attr_reader :pos, :width, :height, :size, :tint

  def initialize(pos:, width: 3, height: 2, size: 64, tint: Color.white)
    @pos = pos
    @width = width
    @height = height
    @size = Vector.all(size)
    @tint = tint
    @tile_map = SquareMap.new
  end

  def build
    [].tap do |out|
      x_range.each do |x|
        y_range.each do |y|
          offset = Vector.new(offset_x(x), offset_y(y))
          offset_pos = pos + offset
          out << Sprite.create(
            pos: offset_pos,
            size:,
            texture: texture(x, y),
            tint:,
          )
        end
      end
    end
  end

  def texture(x, y)
    @tile_map.get_square(x_position(x), y_position(y))
  end

  def offset_x(x)
    return (x * size.x) if width.odd?

    (x * size.x) + (size.x / 2)
  end

  def offset_y(y)
    return (y * size.y) if height.odd?

    (y * size.y) + (size.y / 2)
  end

  def x_range
    return (-w...w) if width.even?

    (-w..w)
  end

  def y_range
    return (-h...h) if height.even?

    (-h..h)
  end

  def w
    @w ||= width / 2
  end

  def h
    @h ||= height / 2
  end

  def x_position(x)
    return :middle if width == 1
    return :left if x == -w
    return :right if x == w && width.odd?
    return :right if x + 1 == w && width.even?

    :middle
  end

  def y_position(y)
    return :middle if height == 1
    return :upper if y == -h
    return :lower if y == h && height.odd?
    return :lower if y + 1 == h && height.even?

    :middle
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
      middle
      left
      right
      upper_left
      upper_middle
      upper_right
      lower_left
      lower_middle
      lower_right
    ]
  end

  def tick
    setup unless ready?

    width, height = FrameInput.screen_size
    Draw.line(start: Vector.new(width / 2, 0), end: Vector.new(width / 2, height))
    Draw.line(start: Vector.new(0, height / 2), end: Vector.new(width, height / 2))

    target_pos = Vector.new(width / 2, height - 150)
    size = Vector.new(800, 250)
    pos = target_pos - (size * 0.5)
    color = Color.crushed_cashew
    color.a = 200

    Draw.rect(pos:, size:, color:)
    Draw.text(
      text: "Width: #{@width}, Height: #{@height}",
      pos: target_pos,
      color: Color.red,
      size: 48,
      halign: :center,
    )
    @width = [@width - 1, 1].max if FrameInput.key_was_down?(:left)
    @width += 1 if FrameInput.key_was_down?(:right)
    @height += 1 if FrameInput.key_was_down?(:up)
    @height = [@height - 1, 1].max if FrameInput.key_was_down?(:down)

    changed_width = FrameInput.key_was_down?(:left) || FrameInput.key_was_down?(:right)
    changed_height = FrameInput.key_was_down?(:up) || FrameInput.key_was_down?(:down)
    rebuild_map if changed_width || changed_height
  end

  def setup
    rebuild_map
    @ready = true
  end

  def ready?
    @ready
  end

  private

  def rebuild_map
    @map ||= []
    @map.each(&:destroy)

    width, height = FrameInput.screen_size
    pos = Vector.new(width / 2, height / 2)
    @width ||= 5
    @height ||= 5

    @map = TileMapRect.new(pos:, width: @width, height: @height).build
  end

  def current_section
    @positions[@position_index]
  end
end

$demo ||= Demo.new
$demo.tick
