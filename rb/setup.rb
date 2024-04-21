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
    { name: 'Entity', id:, pos: pos.inspect }
  end
end

GRAVITY_Y = 7

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
  attr_reader :player

  @current = nil
  def self.current
    @current ||= Game.new
  end

  def initialize
    @ready = false
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
    @player_velocity.y = @player_velocity.y + GRAVITY_Y * dt

    flap_player if FrameInput.key_just_pressed?(:space)
    @player_velocity.y = @player_velocity.y.clamp(-5, 5)
    player.pos = player.pos + @player_velocity

    tick_wall_timer
  end

  private

  def flap_player
    @player_velocity.y -= 4.5
  end

  def tick_wall_timer
    @spawn_timer.tick
    return unless @spawn_timer.finished?

    puts 'Spawn Wall'
    @spawn_timer.reset(3)
  end

  def dt
    FrameInput.delta_time
  end
end
