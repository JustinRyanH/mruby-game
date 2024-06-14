# frozen_string_literal: true

require 'assets/scripts/setup'
require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

# $old_game ||= Game.new
# $old_game.tick

# require 'assets/scripts/setup'
# require 'assets/scripts/new_game'
#
# $new_game ||= TestGame.new
# $new_game.tick
#
class TestRectangle
  include Bounds
  attr_reader :color, :spring
  attr_accessor :pos, :size

  def initialize(width:, height:, x: 0, y: 0, color: Color.red)
    @pos = Vector.new(x, y)
    @current = Vector.new(x, y)
    @size = Vector.new(width, height)
    @color = color
    @spring = Spring.new(12.5, 0.75)
    @velocity = Vector.zero
  end

  def tick
    @current, @velocity = spring.motion(@current, @velocity, @pos)
    Draw.rect(pos: @current, size:, color:, anchor_percentage: Vector.zero)
  end

  def x
    @pos.x
  end

  def y
    @pos.y
  end

  def width
    @size.x
  end

  def height
    @size.y
  end
end

class RectPackTest
  def tick
    setup unless ready?
    @rectangles.each(&:tick)
    Draw.rect(pos: @bound_rect.pos, size: @bound_rect.size, mode: :outline)

    pack_rectangles(@bound_rect.width, @bound_rect.height) if FrameInput.key_just_pressed?(:space)
  end

  def setup
    @ready = true

    screen_size = FrameInput.screen.size
    @rectangles = (0...5).map do
      color = [
        Color.violet,
        Color.lime,
        Color.sky_blue,
        Color.ray_white,
        Color.magenta,
      ].sample
      width = FrameInput.random_int(32..48)
      height = FrameInput.random_int(32..48)
      x = FrameInput.random_int(0..screen_size.x)
      y = FrameInput.random_int(0..screen_size.y)
      TestRectangle.new(x:, y:, width:, height:, color:)
    end

    5.times do
      color = [
        Color.violet,
        Color.lime,
        Color.sky_blue,
        Color.ray_white,
        Color.magenta,
      ].sample
      width = FrameInput.random_int(4..16)
      height = FrameInput.random_int(4..16)
      x = FrameInput.random_int(0..screen_size.x)
      y = FrameInput.random_int(0..screen_size.y)
      @rectangles.push TestRectangle.new(x:, y:, width:, height:, color:)
    end

    @bound_rect = Rectangle.new(pos: screen_size * 0.5, size: Vector.new(100, 300))
  end

  def ready?
    @ready || false
  end

  def pack_rectangles(width, height)
    rc = RectPack.new(width:, height:, num_nodes: 20, heuristic: :best_first)
    rc.pack!(@rectangles)
    @rectangles.each do |rect|
      rect.left += @bound_rect.left
      rect.top += @bound_rect.top
    end
  end
end

$rect_pack ||= RectPackTest.new
$rect_pack.tick
