# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

require 'assets/scripts/setup'
require 'assets/scripts/new_game'

$game ||= TestGame.new
$game.tick
