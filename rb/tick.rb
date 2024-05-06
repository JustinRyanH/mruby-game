# frozen_string_literal: true

# require 'assets/scripts/setup'
require 'assets/scripts/assets'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

class Demo
  attr_reader :volume, :pitch

  def initialize
    @ready = false
  end

  def tick
    setup unless ready?

    Draw.text(text: "Volume: #{volume}", pos: Vector.new(100, 100))
    Draw.text(text: "Pitch: #{pitch}", pos: Vector.new(100, 160))
    @volume += 0.1 if FrameInput.key_was_down?(:up)
    @volume -= 0.1 if FrameInput.key_was_down?(:down)
    @volume = @volume.clamp(0, 1)

    @pitch += 0.1 if FrameInput.key_was_down?(:right)
    @pitch -= 0.1 if FrameInput.key_was_down?(:left)
    @pitch = @pitch.clamp(0, 2)

    @sound.play(volume:, pitch:) if FrameInput.key_was_down?(:p)
  end

  def setup
    @sound = Sounds.flap1
    @volume = 0.5
    @pitch = 1

    @ready = true
  end

  def ready?
    @ready
  end
end

$demo ||= Demo.new
$demo.tick
