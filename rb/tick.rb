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
  attr_reader :color
  attr_accessor :pos, :size

  def initialize(width:, height:, x: 0, y: 0, color: Color.red)
    @pos = Vector.new(x, y)
    @size = Vector.new(width, height)
    @color = color
  end

  def tick
    Draw.rect(pos:, size:, color:, anchor_percentage: Vector.zero)
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

    @rectangles = (0...5).map do
      screen_size = FrameInput.screen.size
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
      Rectangle.new(x:, y:, width:, height:, color:)
    end

    @sum_width = @rectangles.map(&:size).map(&:x).inject(:+) + 20
    @sum_height = @rectangles.map(&:size).map(&:y).inject(:+)

    pack_rectangles(100, 300)
  end

  def ready?
    @ready || false
  end

  def pack_rectangles(width, height)
    rc = RectPack.new(width:, height:, num_nodes: 20)
    rc.pack!(@rectangles)
  end
end

$rect_pack ||= RectPackTest.new
$rect_pack.tick
