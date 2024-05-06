# frozen_string_literal: true

# require 'assets/scripts/setup'
require 'assets/scripts/assets'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

class Demo
  attr_reader :volume

  def initialize
    @ready = false
  end

  def tick
    setup unless ready?

    Draw.text(text: "Volume: #{volume}", pos: Vector.new(100, 100))
    @volume += 0.1 if FrameInput.key_was_down?(:up)
    @volume -= 0.1 if FrameInput.key_was_down?(:down)
    @volume = @volume.clamp(0, 1)
    @sound.play(volume:) if FrameInput.key_was_down?(:p)
  end

  def setup
    @sound = Sounds.flap1
    @volume = 0.5

    @ready = true
  end

  def ready?
    @ready
  end
end

$demo ||= Demo.new
$demo.tick
