# frozen_string_literal: true

require 'assets/scripts/engine_override'
require 'assets/scripts/constants'
require 'assets/scripts/obstacle'
require 'assets/scripts/assets'

def dt
  FrameInput.delta_time
end

class AnimatedEntity
  extend ::Forwardable
  # @return [Animation] animation
  # @return [Entity] entity
  attr_reader :animation, :entity

  def initialize(animation:, entity:)
    @entity = entity
    @animation = animation
  end

  def tick
    animation.update(entity)
  end

  def animation=(new_animation)
    @animation = new_animation
    @animation.force_update(entity)
  end

  def_delegators :@entity, :pos, :pos=, :offscreen_top?, :offscreen_bottom?, :collisions
end

class Animation
  attr_reader :textures

  def initialize(textures)
    @textures = textures
    @current = 0
  end

  def update(entity)
    entity.texture = current_frame if entity.texture.nil?
    return false unless should_update?

    @current = (@current + 1) % textures.size
    puts "#{current_frame.inspect}, #{entity.texture.inspect}"
    entity.texture = current_frame
  end

  def force_update(entity)
    entity.texture = current_frame
  end

  private

  def current_frame
    textures[@current]
  end

  def should_update?
    (FrameInput.id % 20).zero?
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

def random_obstcle(x)
  _, height = FrameInput.screen_size

  gap_width = FrameInput.random_int(40...60)
  gap_size = FrameInput.random_int(150...450)
  size = Vector.new(gap_width, gap_size)
  x += (size.x * 0.5)

  gap_center_y = FrameInput.random_int(((gap_size * 0.5) + 25)...(height - (gap_size * 0.5) - 25))
  pos = Vector.new(x, gap_center_y)
  gap = Rectangle.new(pos:, size:)

  bottom_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: gap.bottom, bottom: height)
  top_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: 0, bottom: gap.top)

  bottom = Entity.create(pos: bottom_rect.pos, size: bottom_rect.size, color: Color.affinity)
  top = Entity.create(pos: top_rect.pos, size: top_rect.size, color: Color.affinity)

  area = Entity.create(pos:, size:, color: Color.blank)
  area.visible = false

  Obstacle.new(top:, bottom:, area:).tap { |obs| Log.info "SpawnObstacle: #{obs.id}" }
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
      halign: :center,
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
              anchor_percentage: Vector.new(0.5, 0.5), color: Color.blunt_violet)
    Draw.text(
      text: 'Game Over',
      pos: Vector.new(width / 2, height / 2),
      size: 96,
      font: Fonts.kenney_future,
      color: Color.white,
      halign: :center,
    )

    return unless @restart_timer.finished?
    return unless FrameInput.key_just_pressed?(:space)

    StartState.new(game)
  end

  def enter
    _, height = FrameInput.screen_size

    game.player.animation = Animation.new([Textures.copter2])

    @player_start = game.player.pos
    @player_end = game.player.pos
    @player_end.y = height + 100

    @death_timer.reset(1)
    @restart_timer.reset(1.2)
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

    if game.debug? && game.obstacles.first
      current = game.obstacles.first
      while current.after?
        after = current.after

        a_pos, b_pos = current.after.challenge_line
        angle = current.after.challenge_angle.abs

        Draw.line(start: a_pos, end: b_pos)
        text = "Angle: #{angle.round(1)}"
        Draw.text(text:, pos: b_pos + Vector.new(16, 32))
        current = after
      end
    end

    all_on_screen = game.obstacles.all?(&:onscreen?)
    generate_obstacles(5) if all_on_screen

    return DeathState.new(game) if game.player.offscreen_top? || game.player.offscreen_bottom?

    return nil unless obstacle_collision

    DeathState.new(game)
  end

  def enter
    Engine.background_color = Color.regal_blue
    game.clear_map
    if game.player.nil?
      create_player
    else
      game.player.pos = starting_position
    end

    width, = FrameInput.screen_size
    obs = random_obstcle(width)
    game.add_obstacle(obs)

    generate_obstacles(5)

    game.player_velocity = Vector.zero
    game.score = 0
    game.player.animation = Animation.new([Textures.copter, Textures.copter3])
  end

  def exit; end

  private

  def challenge_factor(angle)
    case angle
    when 30...35 then return 1
    when 35..40 then return 2
    when 40..180 then return 3
    end
    0
  end

  def generate_obstacles(count)
    count.times do
      last = game.obstacles.last
      random_offset = FrameInput.random_int(150..500)
      obs = random_obstcle(last.x + random_offset)
      game.add_obstacle(obs)

      og_challenge = obs.challenge_angle.abs

      offset = challenge_factor(og_challenge) * FrameInput.random_int(75..150)

      obs.x += offset
      new = obs.challenge_angle.abs
      Log.info("Likely Impossible Extend it: #{og_challenge.round(2)} -> #{new}") if offset.positive?
    end
  end

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
    entity = Entity.create(
      pos: starting_position,
      size: Vector.new(45, 45),
      color: Color.blunt_violet,
    )
    animation = Animation.new([Textures.copter, Textures.copter3])

    game.player = AnimatedEntity.new(animation:, entity:)
  end

  def starting_position
    @starting_position ||= begin
      width, height = FrameInput.screen_size
      Vector.new(width * 0.2, height * 0.5)
    end
  end

  def move_player
    game.player.tick
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
    @obstacles = []
    @score_areas = {}
    @entity_to_obstacle = {}
    @debug = false
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
    toggle_debug if FrameInput.key_was_down?(:f1)

    next_scene = scene.tick
    change_scene(next_scene) unless next_scene.nil?

    process_events
    cleanup
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
  def add_obstacle(obstacle)
    obstacles << obstacle
    obstacle.entity_ids.each do |id|
      @entity_to_obstacle[id] = obstacle
    end

    @last_added&.add_next_obstacle(obstacle)
    @last_added = obstacle
  end

  def debug?
    @debug
  end

  private

  def toggle_debug
    @debug = !@debug
    Log.info('Debug Turned Off') unless @debug
    Log.info('Debug Turned On') unless @debug
  end

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
