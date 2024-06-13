# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $old_game ||= Game.new
# $old_game.tick

require 'assets/scripts/setup'
require 'assets/scripts/new_game'

$new_game ||= TestGame.new
$new_game.tick
