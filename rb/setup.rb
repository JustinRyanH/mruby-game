# frozen_string_literal: true

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

GRAVITY_Y = 7
WORLD_SPEED = 300

class SpawnObstacle
  attr_reader :game

  # @param [Game] game
  def initialize(game)
    @game = game
  end

  def perform
    width, height = FrameInput.screen_size

    gap_width = FrameInput.random_int(40...60)
    gap_size = FrameInput.random_int(120...450)
    size = Vector.new(gap_width, gap_size)
    x = width + size.x + 20

    gap_center_y = FrameInput.random_int(((gap_size * 0.5) + 25)...(height - (gap_size * 0.5) - 25))
    pos = Vector.new(x, gap_center_y)
    gap = Rectangle.new(pos:, size:)

    bottom_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: gap.bottom, bottom: height)
    top_rect = Rectangle.from_bounds(left: gap.left, right: gap.right, top: 0, bottom: gap.top)

    bottom = Entity.create(pos: bottom_rect.pos, size: bottom_rect.size)
    top = Entity.create(pos: top_rect.pos, size: top_rect.size)

    Log.info "SpawnObstacle #{bottom.id}"
    Log.info "SpawnObstacle #{top.id}"
    game.add_obstacle(bottom)
    game.add_obstacle(top)
  end
end

class DestroyObstacle
  attr_reader :game, :entity

  def initialize(game, entity)
    @game = game
    @entity = entity
  end

  def perform
    Log.info("DestroyObstacle #{entity.id}")
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
    game.clear_obstacles
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
    @spawn_timer = Timer.new(0)
  end

  def tick
    tick_wall_timer
    move_player
    move_obstacles
    return DeathState.new(game) if game.player.offscreen_top? || game.player.offscreen_bottom?

    return nil if game.player.collisions.none?

    DeathState.new(game)
  end

  def enter
    game.clear_obstacles
    if game.player.nil?
      create_player
    else
      game.player.pos = starting_position
    end

    game.player_velocity = Vector.zero
    game.spawn_timer = Timer.new(0)
    game.score = 0
  end

  def exit; end

  private

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

  def tick_wall_timer
    @spawn_timer.tick
    return unless @spawn_timer.finished?

    game.add_event(SpawnObstacle.new(game))

    @spawn_timer.reset(FrameInput.random_int(1..2))
  end

  def move_obstacles
    game.obstacles.each do |obstacle|
      obstacle.pos += Vector.new(-WORLD_SPEED, 0) * dt
      game.add_event(DestroyObstacle.new(game, obstacle)) if obstacle.offscreen_left?
    end
  end
end

class Game
  # @return [Game]
  attr_accessor :player

  # @return [Vector]
  attr_accessor :player_velocity
  # @return [Timer]
  attr_accessor :spawn_timer
  # @return [Number]
  attr_accessor :score

  attr_reader :events, :scene, :obstacles

  @current = nil
  def self.current
    @current ||= Game.new
  end

  def initialize
    @scene = GameplayState.new(self)
    @ready = false
    @events = []
    @obstacles = []
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

  def clear_obstacles
    @obstacles.each(&:destroy)
    @obstacles.clear
  end

  def add_obstacle(entity)
    @obstacles << entity
  end

  def obj_count
    @obstacles.size
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
    @obstacles.select!(&:valid?)
  end
end
