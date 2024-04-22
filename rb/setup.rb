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
WORLD_SPEED = 100

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

  def self.test
    puts 'HEY WE CALLED THIS FROM ODIN'
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
    @spawn_timer = Timer.new(0)

    @ready = true
  end

  def ready?
    @ready
  end

  def tick
    setup unless ready?

    process_events
    cleanup

    return if player.collisions.any?

    move_player
    tick_wall_timer
    move_obstacles
  end

  def add_event(event)
    @events << event
  end

  def add_obstacle(entity)
    @obstacles << entity
  end

  def obj_count
    @obstacles.size
  end

  private

  def process_events
    events.each(&:perform)
    events.clear
  end

  def move_obstacles
    @obstacles.each do |obstacle|
      obstacle.pos += Vector.new(-WORLD_SPEED, 0) * dt
      events << DestroyObstacle.new(self, obstacle) if obstacle.offscreen_left?
    end
  end

  def move_player
    @player_velocity.y = @player_velocity.y + (GRAVITY_Y * dt)

    flap_player if FrameInput.key_just_pressed?(:space)
    @player_velocity.y = @player_velocity.y.clamp(-5, 5)
    player.pos += @player_velocity
  end

  def flap_player
    @player_velocity.y -= 4.5
  end

  def tick_wall_timer
    @spawn_timer.tick
    return unless @spawn_timer.finished?

    events << SpawnObstacle.new(self)

    @spawn_timer.reset(FrameInput.random_int(2..4))
  end

  def cleanup
    @obstacles.select!(&:valid?)
  end

  def dt
    FrameInput.delta_time
  end
end
