# frozen_string_literal: true

input = FrameInput.new

# id = input.id
# puts "ID(#{id})"

puts 'Down Key is Down?' if input.key_down?(:down)
puts 'Down Key was Down?' if input.key_was_down?(:down)
# is_down = input.key_down?(:down)

# was_left = Input.was_key_just_release(:left)

# puts "Frame #{id} has Down(#{is_down}), Up(#{is_up}), WasLeft(#{was_left})"
