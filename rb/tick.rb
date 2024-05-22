# frozen_string_literal: true

# require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
def calc_damped_spring_motion(_pos, vel, goal_pos, _freq, _damping)
  [goal_pos, vel]
end

class SpringEpxeriment
  def tick
    width, height = FrameInput.screen_size
    Draw.text(text: 'Spring Example', size: 64, pos: Vector.new(width / 2, 70), color: Color.red, halign: :center)

    @spring_pos ||= Vector.new(width / 2, height / 2)
    @target_x ||= @spring_pos.x
    @spring_velocity ||= Vector.new(0, 0)
    @spring_min ||= 100
    @spring_max ||= width - 100

    x_pos, x_vel = calc_damped_spring_motion(@spring_pos.x, @spring_pos.y, @target_x, 5, 1.0)
    @spring_pos.x = x_pos
    @spring_velocity.x = x_vel

    Draw.rect(pos: Vector.new(width / 2, height / 2), size: Vector.new(@spring_max - @spring_min, 8),
              color: Color.white)
    Draw.rect(pos: @spring_pos, size: Vector.new(75, 75))

    @target_x = FrameInput.mouse_pos.x.clamp(@spring_min, @spring_max) if FrameInput.mouse_just_pressed?(:left)
  end
end

$spring ||= SpringEpxeriment.new
$spring.tick
