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

class StaticObject
  extend ::Forwardable

  attr_reader :pos, :collider

  def initialize(pos:)
    @pos = pos
    @collider = nil
    @sprites = []
  end

  def replace(builder)
    destroy

    builder.pos = pos

    bounds = builder.bounds

    @collider = Collider.create(pos: bounds.pos, size: bounds.size)
    @sprites = builder.build
    self
  end

  def pos=(new_pos)
    new = new_pos - @pos
    @sprites.each { |spr| spr.pos += new }
    @pos = new_pos
    @collider.pos = new_pos
  end

  def destroy
    @sprites.each(&:destroy)
    @collider&.destroy
    @collider = nil
  end

  def collider_id
    collider&.id
  end

  def valid?
    @sprites.all?(&:valid?) && collider_valid?
  end

  def_delegators :@collider, :offscreen_top?, :offscreen_left?, :offscreen_bottom?, :collisions

  private

  def collider_valid?
    return true if @collider.nil?

    @collider.valid?
  end
end
