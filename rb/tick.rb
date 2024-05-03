# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
class SquareMap
  attr_reader :map

  def initialize(map = SQUARE_MAP)
    @map = map
  end

  def get_square(x, y)
    @map[:"#{y}_#{x}"]
  end
end

class TileMapBuilder
  # @param [Vector] ps
  # @param [Color] tint
  attr_accessor :pos, :tint
  attr_reader :width, :height, :size

  def initialize(pos: Vector.zero, width: 3, height: 2, size: 64, tint: Color.white)
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
          out << Sprite.create(
            pos: pos + offset,
            size:,
            texture: texture(x, y),
            tint:,
          )
        end
      end
    end
  end

  def bounds
    new_size = (Vector.new(1, 0) * width) + (Vector.new(0, 1) * height)
    Rectangle.new(pos:, size: new_size)
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
  attr_reader :pos, :bounds

  def initialize(pos:)
    @pos = pos
    @bounds = Rectangle.zero
    @sprites = []
  end

  def replace(builder)
    destroy

    builder.pos = pos

    @bounds = builder.bounds
    @sprites = builder.build
  end

  def destroy
    @sprites.each(&:destroy)
  end
end

class Demo
  def initialize
    @ready = false
  end

  def tick
    setup unless ready?

    width, height = FrameInput.screen_size
    Draw.line(start: Vector.new(width / 2, 0), end: Vector.new(width / 2, height))
    Draw.line(start: Vector.new(0, height / 2), end: Vector.new(width, height / 2))
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
    width, height = FrameInput.screen_size
    pos = Vector.new(width / 2, height / 2)
    @width ||= 5
    @height ||= 5

    obs = StaticObject.new(pos:)
    tmr = TileMapBuilder.new(width: @width, height: @height, tint: Color.affinity)
    obs.replace(tmr)
  end
end

$demo ||= Demo.new
$demo.tick
