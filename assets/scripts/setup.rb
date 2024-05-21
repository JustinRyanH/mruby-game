# frozen_string_literal: true

require 'assets/scripts/imui'
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
  attr_accessor :container_pos
  attr_reader :game, :container_id

  def initialize(game)
    @game = game
    @container_pos = (Vector.new(*FrameInput.screen_size) * 0.5)
    @ready_for_gameplay = false
  end

  def tick
    ImUI.container(:example, pos: container_pos, flex:, transitions:, style: main_style) do |ui|
      @container_id ||= ui.id
      ui.text('Areoaural')
      ui.button('Start', style: button_style, transitions:, hover_style:, down_style:) do |btn|
        @container_pos.x = -2000 if btn.clicked?
      end
      ui.button('Quit', style: button_style, transitions:, hover_style:, down_style:) do |btn|
        # TODO: Do a Exit Transition
        Engine.exit if btn.clicked?
      end
    end

    return GameplayLoadState.new(game) if @ready_for_gameplay

    nil
  end

  def enter
    game.clear_map
    ImUI.ctx.add_transition_observer(self)
  end

  def exit
    ImUI.ctx.remove_transition_observer(self)
  end

  # @param [TransitionAction] action
  def notify(action)
    return unless action.id == @container_id
    return unless action.state == :end

    @ready_for_gameplay = true
  end

  private

  def flex
    @flex ||= Flex.new(justify: :start)
  end

  def transitions
    Transitions.new(
      pos: DefineDistanceTransition.new(pixels_per_second: 2500, ease: :cubic_in),
    )
  end

  def main_style
    @main_style ||= Style.from_hash({ font_size: 120, padding: 8, background_color: Color.crow_black_blue })
  end

  def button_style
    @button_style ||= Style.from_hash({ background_color: Color.magic_spell, text_align: :right, font_size: 74 })
  end

  def hover_style
    @hover_style ||= button_style.merge_new({ background_color: Color.blunt_violet, font_color: Color.magic_spell })
  end

  def down_style
    @down_style ||= hover_style.merge_new({ font_size: hover_style.font_size * 0.98 })
  end

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

    game.debug_draw_obstacles

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

  def exit
  end
end

class GameplayLoadState
  # @return [Game]
  attr_reader :game

  # @param [Game] game
  def initialize(game)
    @game = game
  end

  def tick
    return unless FrameInput.key_just_pressed?(:space)

    next_state = GameplayState.new(game)
    next_state.flap_player
    next_state
  end

  def enter
    game.clear_map
    if game.player.nil?
      create_player
    else
      game.player.pos = starting_position
    end

    width, = FrameInput.screen_size
    obs = game.random_obstcle(width)
    game.add_obstacle(obs)

    game.generate_obstacles(5)

    game.player_velocity = Vector.zero
    game.score = 0
    game.player.animation = Animation.new([Textures.copter, Textures.copter3])
  end

  def exit
  end

  private

  def create_player
    collider = Collider.create(
      pos: game.starting_position,
      size: Vector.new(45, 45),
    )
    sprite = Sprite.create(
      pos: game.starting_position,
      size: Vector.new(45, 45),
      tint: Color.blunt_violet,
      texture: Textures.copter,
    )

    game.player = GameObject.new(collider:, sprite:)
  end
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

    game.debug_draw_obstacles

    all_on_screen = game.obstacles.all?(&:onscreen?)
    game.generate_obstacles(5) if all_on_screen

    return DeathState.new(game) if game.player.offscreen_top? || game.player.offscreen_bottom?

    return nil unless obstacle_collision

    DeathState.new(game)
  end

  def enter
  end

  def exit
  end

  def flap_player
    game.player_velocity.y -= 4.5
    Sounds.explosion.play(volume: 0.2, pitch: 2)
  end

  private

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

  def move_player
    game.player.tick
    game.player_velocity.y = game.player_velocity.y + (GRAVITY_Y * dt)

    flap_player if FrameInput.key_just_pressed?(:space)
    game.player_velocity.y = game.player_velocity.y.clamp(-5, 5)
    game.player.pos += game.player_velocity
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
    @scene = StartState.new(self)
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
    Engine.background_color = Color.regal_blue

    setup unless ready?
    toggle_debug if FrameInput.key_was_down?(:f1)

    next_scene = scene.tick
    change_scene(next_scene) unless next_scene.nil?

    process_events
    cleanup

    ImUI.update
    ImUI.draw
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

  def debug_draw_obstacles
    return unless debug? && obstacles.first

    current = obstacles.first
    while current.after?
      after = current.after
      next if after.nil?

      current = after
    end
  end

  def challenge_factor(angle)
    case angle
    when 30...35 then return 1.25
    when 35..40 then return 1.5
    when 40..180 then return 2
    end
    0
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

    Obstacle.create(gap)
  end

  def generate_obstacles(count)
    count.times do
      last = obstacles.last
      random_offset = FrameInput.random_int(200..500)
      obs = random_obstcle(last.right_most + random_offset)
      add_obstacle(obs)

      og_challenge = obs.challenge_angle.abs

      offset = challenge_factor(og_challenge) * FrameInput.random_int(100..150)

      obs.x += offset
      new = obs.challenge_angle.abs
      Log.info("Likely Impossible Extend it: #{og_challenge.round(2)} -> #{new}") if offset.positive?
    end
  end

  def starting_position
    @starting_position ||= begin
      width, height = FrameInput.screen_size
      Vector.new(width * 0.2, height * 0.5)
    end
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
