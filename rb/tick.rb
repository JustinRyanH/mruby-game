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
    Engine.background_color = Color.crow_black_blue

    center = Vector.new(*FrameInput.screen_size) * 0.5
    main_style = Style.from_hash({ font_size: 60 })
    button_style = Style.from_hash({ background_color: Color.magic_spell })
    hover_style = Style.from_hash({ background_color: Color.blunt_violet, font_color: Color.magic_spell })
    down_style = Style.from_hash({
                                   background_color: Color.blunt_violet,
                                   font_color: Color.magic_spell,
                                   font_size: hover_style.font_size * 0.98
                                 })

    ImUI.container(:example, pos: center, style: main_style) do |ui|
      ui.focus_element = ImUiIcon.new(
        id: :focus_icon,
        texture: Textures.copter,
        pos: Vector.new(100, 100),
        size: Vector.new(32, 32),
        tint: Color.red,
      )

      ui.button('Play Game', style: button_style, hover_style:, down_style:) do |btn|
        ui.focus_element.pos.y = btn.pos.y if btn.focused?
        ui.focus_element.pos.x = ui.left - 32 if btn.focused?
        puts 'Play Game' if btn.clicked?
      end
      ui.button('High Score', style: button_style, hover_style:, down_style:) do |btn|
        ui.focus_element.pos.y = btn.pos.y if btn.focused?
        ui.focus_element.pos.x = ui.left - 32 if btn.focused?
        puts 'Show High Score' if btn.clicked?
      end
      ui.button('Exit', style: button_style, hover_style:, down_style:) do |btn|
        ui.focus_element.pos.y = btn.pos.y if btn.focused?
        ui.focus_element.pos.x = ui.left - 32 if btn.focused?
        if btn.clicked?
          puts 'The game should exit'
          Engine.exit
        end
      end
    end

    ImUI.update
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
