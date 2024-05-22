# frozen_string_literal: true

require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

class SpringEpxeriment
  def tick
    width, height = FrameInput.screen_size
    Draw.text(text: 'Spring Example', size: 64, pos: Vector.new(width / 2, 70), color: Color.red, halign: :center)

    @spring_pos ||= Vector.new(width / 2, height / 2)
    @spring_min ||= 100
    @spring_max ||= width - 100

    Draw.rect(pos: @spring_pos, size: Vector.new(@spring_max - @spring_min, 8), color: Color.white)
    Draw.rect(pos: @spring_pos, size: Vector.new(75, 75))
  end
end

$spring ||= SpringEpxeriment.new
$spring.tick
