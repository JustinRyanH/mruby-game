# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

COLORS = [
  Color.red,
  Color.blue,
  Color.green,
  Color.orange,
  Color.gray,
  Color.dark_purple,
  Color.dark_green,
  Color.purple,
  Color.pink,
].freeze

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

  def initialize(pos:, width: 3, height: 2, size: 64)
    @pos = pos
    @width = width
    @height = height
    @size = Vector.all(size)
  end

  def build
    [].tap do |out|
      x_range.each do |x|
        y_range.each do |y|
          offset = Vector.new(offset_x(x), offset_y(y))
          offset_pos = pos + offset
          tint = COLORS[FrameInput.random_int(0...COLORS.size)]
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

  def texture(x, _y)
    return SQUARE_MAP[:left] if left?(x)

    SQUARE_MAP[:center]
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

  def left?(x)
    return false if width == 1

    x == -w
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
