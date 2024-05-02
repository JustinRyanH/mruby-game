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
