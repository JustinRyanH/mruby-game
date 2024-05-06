# frozen_string_literal: true

require 'assets/scripts/objects'
require 'assets/scripts/animation'
require 'assets/scripts/assets'
require 'assets/scripts/constants'
require 'assets/scripts/engine_override'
require 'assets/scripts/obstacle'

def dt
  FrameInput.delta_time
end

class DestroyObstacle
  attr_reader :game, :collider

  def initialize(game, collider)
    @game = game
    @collider = collider
  end

  def perform
    collider.destroy
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

  def debug_draw_obstacles
    return unless game.debug? && game.obstacles.first

    current = game.obstacles.first
    while current.after?
      after = current.after

      a_pos, b_pos = current.after.challenge_line
      low_a_pos, low_b_pos = current.after.challenge_line_low
      angle = current.after.challenge_angle.abs

      Draw.line(start: a_pos, end: b_pos)
      Draw.line(start: low_a_pos, end: low_b_pos, color: Color.orange)
      text = "Angle: #{angle.round(1)}"
      Draw.text(text:, pos: b_pos + Vector.new(16, 32))
      current = after
    end
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

    debug_draw_obstacles

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

  def random_obstcle(x)
    _, height = FrameInput.screen_size

    gap_width = FrameInput.random_int(40...60)
    gap_size = FrameInput.random_int(150...450)
    size = Vector.new(gap_width, gap_size)
    x += (size.x * 0.5)

    gap_center_y = FrameInput.random_int(((gap_size * 0.5) + 25)...(height - (gap_size * 0.5) - 25))
    pos = Vector.new(x, gap_center_y)
    gap = Rectangle.new(pos:, size:)

    Obstacle.create(gap)
  end

  def challenge_factor(angle)
    case angle
    when 30...35 then return 1
    when 35..40 then return 1.5
    when 40..180 then return 2
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
                      .any? do |evt|
                        evt.entities_leaving.include?(game.player.collider_id)
                      end
    return unless leave_score

    game.score += 1
  end

  def obstacle_collision
    game.player.collisions.any? { |c| game.collider_to_obstacle[c.id].obstacle?(c) }
  end

  def create_player
    collider = Collider.create(
      pos: starting_position,
      size: Vector.new(45, 45),
    )
    sprite = Sprite.create(
      pos: starting_position,
      size: Vector.new(45, 45),
      tint: Color.blunt_violet,
      texture: Textures.copter,
    )

    game.player = GameObject.new(collider:, sprite:)
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
  # @return [Collider] player
  # @return [Number] score
  attr_accessor :player, :score

  # @return [Vector] player_velocity
  # @return [Hash<Integer, Collider>] score_areas
  attr_accessor :score_areas, :player_velocity

  # @return [Array] events
  # @return [Object] scene
  # @return [Array] obstacle
  # @return [Array<Obstacle>] obstacles
  attr_reader :events, :scene, :obstacles

  # @return [Hash<Integer, Obstacle>] events
  attr_reader :collider_to_obstacle

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
    @collider_to_obstacle = {}
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
    obstacle.collider_ids.each do |id|
      @collider_to_obstacle[id] = obstacle
    end

    @last_added&.add_next_obstacle(obstacle)
    @last_added = obstacle
  end

  def debug?
    Engine.debug?
  end

  private

  def toggle_debug
    Engine.debug = !Engine.debug?
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
