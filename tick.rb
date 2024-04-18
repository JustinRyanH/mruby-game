# frozen_string_literal: true

player = Game.player_entity

puts "Player Handle is at: #{player.x}, #{player.y}"
input = FrameInput.new

amount = 100 * input.delta_time

player.x = player.x + amount if input.key_down?(:d)
puts "Move triangle left by #{amount}" if input.key_down?(:a)
