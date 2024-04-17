# frozen_string_literal: true

input = FrameInput.new

id = input.id
puts "ID(#{id})"

input.is_key_down(:down)
# is_up = Input.is_key_down(:up)

# was_left = Input.was_key_just_release(:left)

# puts "Frame #{id} has Down(#{is_down}), Up(#{is_up}), WasLeft(#{was_left})"
