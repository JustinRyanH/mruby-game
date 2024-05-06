# frozen_string_literal: true

# require 'assets/scripts/setup'
require 'assets/scripts/assets'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

class Demo
  def initialize
    @ready = false
  end

  def tick
    setup unless ready?

    @sound.play if FrameInput.key_was_down?(:p)
  end

  def setup
    @sound = Sounds.flap1
  end

  def ready?
    @ready
  end
end

$demo ||= Demo.new
$demo.tick
