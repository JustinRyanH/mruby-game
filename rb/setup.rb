# frozen_string_literal: true

GRAVITY_Y = 7
WORLD_SPEED = 300
DEG_PER_RAD = 360.0 / (Math::PI * 2)

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

  def initialize(top:, bottom:, area:)
    @top = top
    @bottom = bottom
    @area = area
    @area_collisions = Set.new
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
    return nil unless after?

    [area.pos, after.area.pos]
  end

  def challenge_angle
    return nil unless after?

    a, b = challenge_line
    c = b - a

    DEG_PER_RAD * c.normalize.angle
  end

  private

  # @return [Set<Entity]
  attr_reader :area_collisions

  def entities
    @entities ||= [top, bottom, area]
  end
end

class Fonts
  def self.kenney_future
    @kenney_future ||= AssetSystem.add_font('assets/fonts/Kenney Future.ttf')
  end
end

def dt
  FrameInput.delta_time
end

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

Entity.class_eval do
  def inspect
    { name: 'Entity', id:, pos: pos.inspect, size: size.inspect }
  end

  def offscreen_left?
    right = pos.x + (size.x * 0.5)
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

def random_obstcle(game:, x:)
  _, height = FrameInput.screen_size

  gap_width = FrameInput.random_int(40...60)
  gap_size = FrameInput.random_int(150...450)
  size = Vector.new(gap_width, gap_size)

  gap_center_y = FrameInput.random_int(((gap_size * 0.5) + 25)...(height - (gap_size * 0.5) - 25))
  pos = Vector.new(x, gap_center_y)
  gap = Rectangle.new(pos:, size:)

  bottom_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: gap.bottom, bottom: height)
  top_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: 0, bottom: gap.top)

  bottom = Entity.create(pos: bottom_rect.pos, size: bottom_rect.size)
  top = Entity.create(pos: top_rect.pos, size: top_rect.size)

  area = Entity.create(pos:, size:, color: Color.red)
  area.visible = false

  obs = Obstacle.new(top:, bottom:, area:)

  Log.info "SpawnObstacle: #{obs.id}"
  game.abb_obstacle(obs)
end

class SpawnObstacle
  attr_reader :game

  # @param [Game] game
  def initialize(game)
    @game = game
  end

  def perform
    x = width + size.x + 20

    random_obstcle(game:, x:)
  end
end

class DestroyObstacle
  attr_reader :game, :entity

  def initialize(game, entity)
    @game = game
    @entity = entity
  end

  def perform
    entity.destroy
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

class StartState
  attr_reader :game

  def initialize(game)
    @game = game
  end

  def tick
    width, height = FrameInput.screen_size

    text_args = {
      text: 'PRESS `Space`',
      font: Fonts.kenney_future,
      size: 96
    }

    text_size = Draw.measure_text(**text_args) + Vector.new(32, 0)
    Draw.rect(pos: Vector.new(width / 2, height / 2), size: text_size,
              anchor_percentage: Vector.new(0.5, 0.5), color: Color.blue)
    Draw.text(
      **text_args,
      pos: Vector.new(width / 2, height / 2),
      font: Fonts.kenney_future,
      color: Color.white,
      halign: :center
    )

    return unless FrameInput.key_just_pressed?(:space)

    GameplayState.new(game)
  end

  def enter
    game.clear_map
    if game.player.nil?
      create_player
    else
      game.player.pos = starting_position
    end
  end

  def exit; end

  private

  def starting_position
    @starting_position ||= begin
      width, height = FrameInput.screen_size
      Vector.new(width * 0.2, height * 0.5)
    end
  end
end

class DeathState
  attr_reader :game

  # @param [Game] game
  def initialize(game)
    @game = game
    @death_timer = Timer.new
    @restart_timer = Timer.new
  end

  def tick
    @death_timer.tick
    @restart_timer.tick

    game.player.pos = @player_start.lerp(@player_end, @death_timer.percentage)

    width, height = FrameInput.screen_size
    Draw.rect(pos: Vector.new(width / 2, height / 2), size: Vector.new(700, 80),
              anchor_percentage: Vector.new(0.5, 0.5), color: Color.blue)
    Draw.text(
      text: 'Game Over',
      pos: Vector.new(width / 2, height / 2),
      size: 96,
      font: Fonts.kenney_future,
      color: Color.white,
      halign: :center
    )

    return unless @restart_timer.finished?
    return unless FrameInput.key_just_pressed?(:space)

    StartState.new(game)
  end

  def enter
    _, height = FrameInput.screen_size

    @player_start = game.player.pos
    @player_end = game.player.pos
    @player_end.y = height + 100

    @death_timer.reset(0.5)
    @restart_timer.reset(0.75)
  end

  def exit; end
end

class GameplayState
  # @return [Game]
  attr_reader :game

  # @param [Game] game
  def initialize(game)
    @game = game
  end

  def tick
    move_player
    move_world

    check_for_score

    text_args = { text: "SCORE: #{game.score}", font: Fonts.kenney_future, size: 32 }

    text_size = Draw.measure_text(**text_args) + Vector.new(32, 16)
    Draw.rect(pos: Vector.new(16, 48), size: text_size,
              anchor_percentage: Vector.new(0.0, 0.5), color: Color.blue)
    Draw.text(**text_args, pos: Vector.new(32, 48), font: Fonts.kenney_future, color: Color.white, halign: :left)

    if game.obstacles.first
      current = game.obstacles.first
      while current.after?
        after = current.after

        a_pos, b_pos = current.challenge_line

        a_lower = Vector.new(a_pos.x, 0)
        b_lower = Vector.new(b_pos.x, 0)
        length = (b_lower - a_lower).length
        angle = current.challenge_angle

        Draw.line(start: a_pos, end: b_pos)
        Draw.text(text: "Angle: #{angle.round(2)}", pos: a_pos + Vector.new(16, 32))
        Draw.text(text: "Length: #{length.round(2)}", pos: a_pos + Vector.new(16, 64))
        current = after
      end
    end

    return DeathState.new(game) if game.player.offscreen_top? || game.player.offscreen_bottom?

    return nil unless obstacle_collision

    DeathState.new(game)
  end

  def enter
    game.clear_map
    if game.player.nil?
      create_player
    else
      game.player.pos = starting_position
    end

    game.player_velocity = Vector.zero
    game.score = 0
  end

  def exit; end

  private

  def check_for_score
    leave_score = game.obstacles
                      .map(&:check_area_collisions)
                      .any? { |evt| evt.entities_leaving.include?(game.player) }
    return unless leave_score

    game.score += 1
  end

  def obstacle_collision
    game.player.collisions
        .any? { |e| game.entity_to_obstacle[e.id].obstacle?(e) }
  end

  def create_player
    game.player = Entity.create(
      pos: starting_position,
      size: Vector.new(45, 45),
      color: Color.red
    )
  end

  def starting_position
    @starting_position ||= begin
      width, height = FrameInput.screen_size
      Vector.new(width * 0.2, height * 0.5)
    end
  end

  def move_player
    game.player_velocity.y = game.player_velocity.y + (GRAVITY_Y * dt)

    flap_player if FrameInput.key_just_pressed?(:space)
    game.player_velocity.y = game.player_velocity.y.clamp(-5, 5)
    game.player.pos += game.player_velocity
  end

  def flap_player
    game.player_velocity.y -= 4.5
  end

  def move_world
    game.obstacles.each(&:update)
    game.obstacles.select(&:offscreen_left?).each do |obs|
      game.add_event(DestroyObstacle.new(game, obs))
    end
  end
end

class Game
  # @return [Entity] player
  # @return [Number] score
  attr_accessor :player, :score

  # @return [Vector] player_velocity
  # @return [Hash<Integer, Entity>] score_areas
  attr_accessor :score_areas, :player_velocity

  # @return [Array] events
  # @return [Object] scene
  # @return [Array] obstacle
  # @return [Array<Obstacle>] obstacles
  attr_reader :events, :scene, :obstacles

  # @return [Hash<Integer, Obstacle>] events
  attr_reader :entity_to_obstacle

  @current = nil
  def self.current
    @current ||= Game.new
  end

  def initialize
    @scene = GameplayState.new(self)
    @ready = false
    @events = []
    @obstacles_queue = []
    @obstacles = []
    @score_areas = {}
    @entity_to_obstacle = {}
  end

  def setup
    @scene.enter

    @ready = true
  end

  def ready?
    @ready
  end

  def tick
    setup unless ready?

    process_events
    cleanup

    next_scene = scene.tick
    change_scene(next_scene) unless next_scene.nil?
  end

  def add_event(event)
    @events << event
  end

  def clear_map
    obstacles.each(&:destroy)
    obstacles.clear
    score_areas.clear
    @last_added = nil
  end

  # @param [Obstacle] obstacle
  def abb_obstacle(obstacle)
    obstacles << obstacle
    obstacle.entity_ids.each do |id|
      @entity_to_obstacle[id] = obstacle
    end

    @last_added&.add_next_obstacle(obstacle)
    @last_added = obstacle
  end

  private

  def change_scene(new_scene)
    scene.exit
    @scene = new_scene
    scene.enter
  end

  def process_events
    events.each(&:perform)
    events.clear
  end

  def cleanup
    obstacles.select!(&:valid?)
    @score_areas.select! { |_, obstacle| obstacle.valid? }
  end
end
