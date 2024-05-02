# frozen_string_literal: true

class GameObject
  extend ::Forwardable

  # @return [Collider] collider
  # @return [Sprite] sprite
  attr_reader :collider, :sprite

  def initialize(collider: nil, sprite: nil)
    @collider = collider
    @sprite = sprite
    @animation = nil
  end

  def pos
    @collider.pos
  end

  def pos=(value)
    @collider&.pos = value
    @sprite&.pos = value
  end

  def animation=(new_animation)
    @animation = new_animation
    @animation.force_update(sprite)
  end

  def tick
    @animation&.update(sprite)
  end

  def destroy
    [sprite, collider].compact.each(&:destroy)
  end

  def valid?
    [sprite, collider].compact.all?(&:valid?)
  end

  def id
    @id ||= [collider&.id, sprite&.id].compact.join(':')
  end

  def collider_id
    collider&.id
  end

  def_delegators :@collider, :offscreen_top?, :offscreen_left?, :offscreen_bottom?, :collisions
end
