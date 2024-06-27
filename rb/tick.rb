# frozen_string_literal: true

require 'assets/scripts/setup'
require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

$old_game ||= Game.new
$old_game.tick

# require 'assets/scripts/setup'
# require 'assets/scripts/new_game'
#
require 'assets/scripts/assets'
# $new_game ||= TestGame.new
# $new_game.tick
