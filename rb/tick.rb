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
    @timer.tick
    ImUI.update
    Engine.background_color = Color.crow_black_blue

    center = Vector.new(*FrameInput.screen_size) * 0.5
    main_style = Style.from_hash({ font_size: 60 })
    button_style = Style.from_hash({ background_color: Color.magic_spell })
    hover_style = Style.from_hash({ background_color: Color.blunt_violet })

    ImUI.container(:example, pos: center, style: main_style) do |ui|
      ui.button('Button A', style: button_style, hover_style:) do |btn|
        puts 'The Mouse Button A was clicked!' if btn.clicked?
      end
      ui.button('Button B', style: button_style, hover_style:) do |btn|
        puts 'The Mouse Button B was clicked!' if btn.clicked?
      end
    end

    ImUI.draw
  end

  def setup
    @style = Style.from_hash({ padding: 16 })
    @timer = Timer.new(180)
    @ready = true
  end

  def ready?
    @ready
  end
end

$demo ||= Demo.new
$demo.tick
