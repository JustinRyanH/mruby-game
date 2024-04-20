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

GRAVITY_Y = 7

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
    puts 'Game Setup'
    width, height = FrameInput.screen_size

    @player = Entity.create(
      pos: Vector.new(width * 0.2, height * 0.5),
      size: Vector.new(45, 45),
      color: Color.red
    )

    @player_velocity = Vector.zero

    @ready = true
  end

  def ready?
    @ready
  end

  def tick
    setup unless ready?
    @player_velocity.y = [@player_velocity.y + GRAVITY_Y * dt, 20].min

    flap_player if FrameInput.key_just_pressed?(:space)
    @player_velocity.y = @player_velocity.y.clamp(-100, 100)

    player.y += @player_velocity.y
    player.x += @player_velocity.x
  end

  private

  def flap_player
    @player_velocity.y -= 4.5
  end

  def dt
    FrameInput.delta_time
  end
end
