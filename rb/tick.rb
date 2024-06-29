# frozen_string_literal: true

# require 'assets/scripts/setup'
# require 'assets/scripts/engine_override'
# h = {}
# ObjectSpace.count_objects(h)
# pugts h

# $old_game ||= Game.new
# $old_game.tick
#

class RevealGame
  def tick
    setup unless ready?
    screen = FrameInput.screen

    text_pos = Vector.new(screen.size.x * 0.5, screen.size.y - 72)
    Draw.text(text: 'Sonar Test', pos: text_pos, halign: :center, size: 60)
  end

  private

  def ready?
    @ready || false
  end

  def setup
    @ready = true
  end
end

$game ||= RevealGame.new
$game.tick
