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
    screen_size = FrameInput.screen.size
    pack_rectangles(@bound_rect.width, @bound_rect.height, :best_fit) if FrameInput.key_just_pressed?(:a)
    pack_rectangles(@bound_rect.width, @bound_rect.height, :bottom_left) if FrameInput.key_just_pressed?(:d)
    if @current_pack == :best_fit
      Draw.text(text: 'Best Fit', pos: Vector.new(screen_size.x * 0.5, screen_size.y - 70), size: 64, color: Color.red,
                halign: :center)
    end
    return unless @current_pack == :bottom_left

    Draw.text(text: 'Bottom First', pos: Vector.new(screen_size.x * 0.5, screen_size.y - 70), size: 64,
              color: Color.red, halign: :center)
  end

  def setup
    @ready = true

    colors = [
      Color.violet,
      Color.lime,
      Color.sky_blue,
      Color.ray_white,
      Color.magenta,
      Color.dark_green,
      Color.maroon,
      Color.orange,
      Color.beige,
      Color.dreamy_sunset,
      Color.blunt_violet,
      Color.magic_spell,
      Color.regal_blue,
    ]

    screen_size = FrameInput.screen.size
    @rectangles = (0...10).map do
      color = colors.sample
      width = FrameInput.random_int(32..48)
      height = FrameInput.random_int(32..48)
      x = FrameInput.random_int(0..screen_size.x)
      y = FrameInput.random_int(0..screen_size.y)
      TestRectangle.new(x:, y:, width:, height:, color:)
    end

    15.times do
      color = colors.sample
      width = FrameInput.random_int(8..16)
      height = FrameInput.random_int(8..16)
      x = FrameInput.random_int(0..screen_size.x)
      y = FrameInput.random_int(0..screen_size.y)
      @rectangles.push TestRectangle.new(x:, y:, width:, height:, color:)
    end

    @bound_rect = Rectangle.new(pos: screen_size * 0.5, size: Vector.new(100, 300))
  end

  def ready?
    @ready || false
  end

  def pack_rectangles(width, height, heuristic)
    rc = RectPack.new(width:, height:, num_nodes: 20, heuristic:)
    rc.pack!(@rectangles)
    @rectangles.each do |rect|
      rect.left += @bound_rect.left
      rect.top += @bound_rect.top
    end
    @current_pack = heuristic
  end
end

$rect_pack ||= RectPackTest.new
$rect_pack.tick
