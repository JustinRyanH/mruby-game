# frozen_string_literal: true

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
end

GRAVITY_Y = 7
WORLD_SPEED = 100

class SpawnObstacle
  attr_reader :game

  # @param [Game] game
  def initialize(game)
    @game = game
  end

  def perform
    width, _height = FrameInput.screen_size

    x = width / 2

    gap_center_y = FrameInput.random_float(200...500)
    pos = Vector.new(x, gap_center_y)

    Log.info("SpawnObstacle @ #{pos.inspect}")
    entity = Entity.create(pos:, size: Vector.new(40, 100))
    game.add_obstacle(entity)
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

  def initialize(time)
    @time = time
  end

  def tick
    @time -= FrameInput.delta_time
  end

  def reset(time)
    @time = time
  end

  def finished?
    @time <= 0
  end
end

class Game
  attr_reader :player, :player_velocity, :events

  @current = nil
  def self.current
    @current ||= Game.new
  end

  def initialize
    @ready = false
    @events = []
    @obstacles = []
  end

  def setup
    Log.info('Setting Up Game')
    width, height = FrameInput.screen_size

    @player = Entity.create(
      pos: Vector.new(width * 0.2, height * 0.5),
      size: Vector.new(45, 45),
      color: Color.red
    )
    @player_velocity = Vector.zero
    @spawn_timer = Timer.new(3)

    @ready = true
  end

  def ready?
    @ready
  end

  def tick
    setup unless ready?

    process_events

    @player_velocity.y = @player_velocity.y + (GRAVITY_Y * dt)

    flap_player if FrameInput.key_just_pressed?(:space)
    @player_velocity.y = @player_velocity.y.clamp(-5, 5)
    player.pos += @player_velocity

    tick_wall_timer
    move_obstacles
  end

  def add_obstacle(entity)
    @obstacles << entity
  end

  private

  def process_events
    events.each(&:perform)
    events.clear
  end

  def move_obstacles
    # TOOD: We really should just clean this up
    @obstacles.select!(&:valid?)
    @obstacles.each do |obstacle|
      obstacle.pos += Vector.new(-WORLD_SPEED, 0) * dt
      events << DestroyObstacle.new(self, obstacle) if obstacle.offscreen_left?
    end
  end

  def flap_player
    @player_velocity.y -= 4.5
  end

  def tick_wall_timer
    @spawn_timer.tick
    return unless @spawn_timer.finished?

    events << SpawnObstacle.new(self)

    @spawn_timer.reset(3)
  end

  def dt
    FrameInput.delta_time
  end
end

puts FrameInput.random_float(3...5)
