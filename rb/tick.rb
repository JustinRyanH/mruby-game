# frozen_string_literal: true

# require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
require 'assets/scripts/engine_override'
require 'assets/scripts/assets'
require 'assets/scripts/imui'

class Demo
  attr_reader :volume, :pitch

  def initialize
    @ready = false
  end

  def tick
    setup unless ready?
    Engine.background_color = Color.crow_black_blue

    center = Vector.new(*FrameInput.screen_size) * 0.5
    ImUI.container(:example, pos: center) do |ui|
      ui.text('Immediate Mode GUI')
      ui.text('Test')
    end
  end

  def setup
    @style = Style.from_hash({ padding: 16 })
    @ready = true
  end

  def ready?
    @ready
  end
end

$demo ||= Demo.new
$demo.tick
