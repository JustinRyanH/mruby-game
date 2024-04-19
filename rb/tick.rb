# frozen_string_literal: true

player = Game.player_entity

amount = 100 * FrameInput.delta_time

player.x += amount if FrameInput.key_down?(:d)
player.x -= amount if FrameInput.key_down?(:a)
player.y -= amount if FrameInput.key_down?(:w)
player.y += amount if FrameInput.key_down?(:s)
