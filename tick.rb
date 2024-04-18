# frozen_string_literal: true

player = Game.player_entity

input = FrameInput.new

amount = 100 * input.delta_time

player.x += amount if input.key_down?(:d)
player.x -= amount if input.key_down?(:a)
player.y -= amount if input.key_down?(:w)
player.y += amount if input.key_down?(:s)
