# frozen_string_literal: true

require 'assets/scripts/tilemap'


class CollisionEvent
  # @param [Array<Collider>] entities_leaving
  # @param [Array<Collider>] entities_entering
  attr_accessor :entities_leaving, :entities_entering

  def initialize
    @entities_leaving = Set.new
    @entities_entering = Set.new
  end
end

class Obstacle
  # @return [Collider] top
  # @return [Collider] bottom
  # @return [Collider] area
  attr_reader :top, :bottom, :area

  # @return [Obstacle, nil] before
  # @return [Obstacle, nil] after
  attr_accessor :before, :after

  def self.create(gap)
    _, height = FrameInput.screen_size
    pos = gap.pos
    size = gap.size

    rand_width = FrameInput.random_int(2..5)

    bottom_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: gap.bottom, bottom: height)
    top_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: 0, bottom: gap.top)

    area_collider = Collider.create(pos:, size:)
    area = GameObject.new(collider: area_collider)

    bottom_height = (bottom_rect.size.y / 64).ceil
    btm_tmb = TileMapBuilder.new(width: rand_width, height: bottom_height + 1, size: 64, tint: Color.affinity)
    bottom = StaticObject.new(pos: bottom_rect.pos).replace(btm_tmb)

    bottom.pos += Vector.new(0, area.bottom - bottom.top)

    top_height = (top_rect.size.y / 64).ceil
    btm_tmb = TileMapBuilder.new(width: rand_width, height: top_height + 1, size: 64, tint: Color.affinity)
    top = StaticObject.new(pos: top_rect.pos).replace(btm_tmb)
    top.pos += Vector.new(0, area.top - top.bottom)

    Obstacle.new(top:, bottom:, area:)
  end

  def initialize(top:, bottom:, area:, game: nil)
    @top = top
    @bottom = bottom
    @area = area
    @area_collisions = Set.new
    @game = game || Game.current
  end

  def update
    top.pos += Vector.new(-WORLD_SPEED, 0) * dt
    bottom.pos += Vector.new(-WORLD_SPEED, 0) * dt
    area.pos += Vector.new(-WORLD_SPEED, 0) * dt
  end

  def add_exit_event(evt)
    @on_area_exit << evt
  end

  def id
    entities.map(&:id).join(':')
  end

  def x
    area.pos.x
  end

  def x=(new_x)
    area.pos = Vector.new(new_x, area.pos.y)
    top.pos = Vector.new(new_x, top.pos.y)
    bottom.pos = Vector.new(new_x, bottom.pos.y)
  end

  def destroy
    before.clear_after if !before.nil? && before.after == self
    after.clear_before if !after.nil? && after.before == self

    [top, bottom, area].each(&:destroy)
  end

  def after?
    !after.nil?
  end

  def before?
    !before.nil?
  end

  def clear_before
    @before = nil
  end

  def clear_after
    @after = nil
  end

  def add_next_obstacle(obstacle)
    @after = obstacle
    obstacle.before = self
  end

  def onscreen?
    area.collider.onscreen?
  end

  def offscreen_left?
    entities.all?(&:offscreen_left?)
  end

  def obstacle?(collider)
    top.collider_id == collider.id || bottom.collider_id == collider.id
  end

  def area?(entity)
    area == entity
  end

  def valid?
    entities.all?(&:valid?)
  end

  def collider_ids
    entities.map(&:collider_id).compact
  end

  def entity_ids
    entities.map(&:id)
  end

  def check_area_collisions
    CollisionEvent.new.tap do |evt|
      new_collisions = Set.new(area.collisions.map(&:id))
      next evt unless @area_collisions.any? || new_collisions.any?

      evt.entities_leaving = @area_collisions - new_collisions
      evt.entities_entering = new_collisions - @area_collisions

      @area_collisions = new_collisions
    end
  end

  def challenge_line
    return nil unless before?

    [area.pos, before.area.pos]
  end

  def challenge_angle
    return nil unless before?

    a, b = challenge_line
    get_angle(a, b)
  end

  def overlap_top
    return nil unless before?

    area.bottom - before.area.top
  end

  def overlap_bottom
    return nil unless before?

    area.top - before.area.bottom
  end

  def cross_over_bottom_distance
    return nil unless before?

    a, b = cross_over_bottom
    (b - a).length
  end

  def cross_over_top_distance
    return nil unless before?

    a, b = cross_over_top
    (b - a).length
  end

  def cross_over_top
    return nil unless before?

    a = Vector.new(top.left, area.bottom)
    b = Vector.new(before.top.right, before.area.top)
    [a, b]
  end

  def cross_over_bottom
    return nil unless before?

    a = Vector.new(top.left, area.top)
    b = Vector.new(before.top.right, before.area.bottom)
    [a, b]
  end

  def left_most
    [top.left, bottom.left].max
  end

  def right_most
    [top.right, bottom.right].max
  end

  private

  def get_angle(a, b)
    c = a - b

    DEG_PER_RAD * c.normalize.angle
  end

  # @return [Set<Entity] area_collisions
  # @return [Game] game
  attr_reader :area_collisions
  attr_reader :game

  def entities
    @entities ||= [top, bottom, area]
  end
end
