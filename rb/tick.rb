# frozen_string_literal: true

require 'assets/scripts/setup'
require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $old_game ||= Game.new
# $old_game.tick

# require 'assets/scripts/setup'
# require 'assets/scripts/new_game'
#
# $new_game ||= TestGame.new
# $new_game.tick
#
class Rectangle
  attr_reader :x, :y, :width, :height, :color

  def initialize(width:, height:, x: 0, y: 0, color: Color.red)
    @x = x
    @y = y
    @width = width
    @height = height
    @color = color
  end

  def tick
    Draw.rect(pos: Vector.new(x, y), size: Vector.new(width, height), color:)
  end
end

class RectPackTest
  def tick
    setup unless ready?
    center = FrameInput.screen.size * 0.5
    @rectangles.each(&:tick)
    Draw.rect(pos: center, size: Vector.new(@sum_width, @sum_height), mode: :outline)
  end

  def setup
    @ready = true

    @rectangles = (0..5).map do
      screen_size = FrameInput.screen.size
      color = [
        Color.violet,
        Color.lime,
        Color.sky_blue,
        Color.ray_white,
        Color.magenta,
      ].sample
      width = FrameInput.random_int(32..128)
      height = FrameInput.random_int(32..128)
      x = FrameInput.random_int(0..screen_size.x)
      y = FrameInput.random_int(0..screen_size.y)
      Rectangle.new(x:, y:, width:, height:, color:)
    end
    @sum_width = @rectangles.map(&:width).inject(:+)
    @sum_height = @rectangles.map(&:width).inject(:+)
  end

  def ready?
    @ready || false
  end
end

$rect_pack ||= RectPackTest.new
$rect_pack.tick
