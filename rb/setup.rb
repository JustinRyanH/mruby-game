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

class Game
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
      size: Vector.new(90, 90),
      color: Color.red
    )

    @ready = true
  end

  def ready?
    @ready
  end

  def tick
    setup unless ready?
  end
end
