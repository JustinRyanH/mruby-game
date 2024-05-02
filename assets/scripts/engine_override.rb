# frozen_string_literal: true

Vector.class_eval do
  def inspect
    { name: 'Vector', x:, y: }
  end
end

Color.class_eval do
  def inspect
    { name: 'Color', red:, blue:, green:, alpha: }
  end
end

Collider.class_eval do
  def inspect
    { name: 'Collider', id:, pos: pos.inspect, size: size.inspect }
  end

  def onscreen?
    !offscreen_bottom? && !offscreen_right? && !offscreen_left? && !offscreen_top?
  end

  def offscreen_left?
    right = pos.x + (size.x * 0.5)
    right.negative?
  end

  def offscreen_right?
    width, = FrameInput.screen_size
    right = width - (pos.x + (size.x * 0.5))
    right.negative?
  end

  def offscreen_top?
    top = pos.y - (size.y * 0.5)
    top.negative?
  end

  def offscreen_bottom?
    _, height = FrameInput.screen_size
    bottom = height - (pos.y + (size.y * 0.5))
    bottom.negative?
  end

  def colliding_with?(entity)
    collisions.include?(entity)
  end
end

Texture.class_eval do
  def inspect
    { name: 'Texture', id: }
  end
end

# TODO: Make this map from RL Rectangle
class Rectangle
  attr_reader :pos, :size

  def self.from_bounds(top:, right:, bottom:, left:)
    height = (bottom - top).abs
    width = (right - left).abs

    center_y = top + (height * 0.5)
    center_x = left + (width * 0.5)

    pos = Vector.new(center_x, center_y)
    size = Vector.new(width, height)
    new(pos:, size:)
  end

  def initialize(pos:, size:)
    @pos = pos
    @size = size
  end

  def bottom
    pos.y + (size.y * 0.5)
  end

  def top
    pos.y - (size.y * 0.5)
  end

  def left
    pos.x - (size.x * 0.5)
  end

  def right
    pos.x + (size.x * 0.5)
  end

  def inspect
    { name: 'Rectangle', top:, right:, bottom:, left: }
  end
end

class Timer
  attr_reader :time

  def initialize(time = 0)
    @time = time
    @total_time = time
  end

  def tick
    return unless @time.positive?

    @time -= FrameInput.delta_time
  end

  def reset(time)
    @time = time
    @total_time = time
  end

  def finished?
    @time <= 0
  end

  def percentage
    [1 - (@time / @total_time), 1].min
  end
end
