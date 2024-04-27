# frozen_string_literal: true

class CollisionEvent
  # @param [Array<Entity>] entities_leaving
  # @param [Array<Entity>] entities_entering
  attr_accessor :entities_leaving, :entities_entering

  def initialize
    @entities_leaving = Set.new
    @entities_entering = Set.new
  end
end

class Obstacle
  # @return [Entity] top
  # @return [Entity] bottom
  # @return [Entity] area
  attr_reader :top, :bottom, :area

  # @return [Obstacle, nil] before
  # @return [Obstacle, nil] after
  attr_accessor :before, :after

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

    Log.info("Destroy: #{id}")
    top.destroy
    bottom.destroy
    area.destroy
  end

  def after?
    !after.nil?
  end

  def before?
    !before.nil?
  end

  def clear_before
    Log.info("Clear Before: #{before.id}")
    @before = nil
  end

  def clear_after
    Log.info("Clear After: #{after.id}")
    @after = nil
  end

  def add_next_obstacle(obstacle)
    @after = obstacle
    obstacle.before = self
  end

  def onscreen?
    area.onscreen?
  end

  def offscreen_left?
    entities.all?(&:offscreen_left?)
  end

  def obstacle?(entity)
    top == entity || bottom == entity
  end

  def area?(entity)
    area == entity
  end

  def valid?
    entities.all?(&:valid?)
  end

  def entity_ids
    entities.map(&:id)
  end

  def eql?(other)
    id == other.id
  end

  def check_area_collisions
    CollisionEvent.new.tap do |evt|
      new_collisions = Set.new(area.collisions)
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
    c = a - b

    DEG_PER_RAD * c.normalize.angle
  end

  private

  # @return [Set<Entity] area_collisions
  # @return [Game] game
  attr_reader :area_collisions
  attr_reader :game

  def entities
    @entities ||= [top, bottom, area]
  end
end
