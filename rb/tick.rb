# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h
#
$spr ||= Sprite.new(0)

$game ||= Game.new
$game.tick
