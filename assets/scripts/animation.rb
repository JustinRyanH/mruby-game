# frozen_string_literal: true

class Animation
  attr_reader :textures

  def initialize(textures)
    @textures = textures
    @current = 0
  end

  def update(sprite)
    sprite.texture = current_frame if sprite.texture.nil?
    return false unless should_update?

    @current = (@current + 1) % textures.size
    sprite.texture = current_frame
  end

  def force_update(sprite)
    sprite.texture = current_frame
  end

  private

  def current_frame
    textures[@current]
  end

  def should_update?
    (FrameInput.id % 20).zero?
  end
end
