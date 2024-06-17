# frozen_string_literal: true

# require 'assets/scripts/setup'
# require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

# $old_game ||= Game.new
# $old_game.tick

# require 'assets/scripts/setup'
# require 'assets/scripts/new_game'
#
# $new_game ||= TestGame.new
# $new_game.tick

class TexturePacking
  def tick
    setup unless ready?
  end

  def setup
    @ready = true
  end

  def ready?
    @ready || false
  end
end

$packing ||= TexturePacking.new
$packing.tick
