# frozen_string_literal: true

input = FrameInput.new

amount = 1 * input.delta_time

puts "Move triangle right by #{amount}" if input.key_down?(:d)
puts "Move triangle left by #{amount}" if input.key_down?(:a)
