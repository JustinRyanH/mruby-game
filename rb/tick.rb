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
    @rectangles.each(&:tick)
  end

  def setup
    @ready = true
    @rectangles = (0..5).map do
      color = [
        Color.violet,
        Color.lime,
        Color.sky_blue,
        Color.ray_white,
        Color.magenta,
      ].sample
      width = FrameInput.random_int(32..128)
      height = FrameInput.random_int(32..128)
      Rectangle.new(width:, height:, color:)
    end
  end

  def ready?
    @ready || false
  end
end

$rect_pack ||= RectPackTest.new
$rect_pack.tick
