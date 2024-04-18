# frozen_string_literal: true

input = FrameInput.new
puts 'Down Key is Down?' if input.key_down?(:down)
puts 'Down Key was Down?' if input.key_was_down?(:down)
