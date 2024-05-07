# frozen_string_literal: true

# require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
require 'assets/scripts/engine_override'
require 'assets/scripts/assets'

class Style
  attr_writer :padding

  def padding
    @padding ||= 8
  end
end

class ImUiText
  attr_reader :message, :pos, :size, :font

  def initialize(message)
    @message = message
    @size = 32
    @font = Fonts.kenney_future
  end

  def dimensions
    Draw.measure_text(text: message, size:, font:)
  end

  def draw; end
end

class ImUiContainer
  attr_reader :style

  def initialize(
    size: Vector.new(100, 200),
    pos: Vector.new(*FrameInput.screen_size) * 0.5,
    style: Style.new
  )
    @style = style
    @pos = pos
    @size = size
    @elements = []
  end

  def text(message)
    @elements << ImUiText.new(message)
  end

  def draw
    dimensions = @elements.map(&:dimensions)
    height = dimensions.inject(0) { |sum, dim| sum + dim.y + style.padding } + style.padding
    width = dimensions.inject(0) { |max, dim| [max, dim.x].max } + (style.padding * 2)

    calculated_size = Vector.new(width, height)
    rect = Rectangle.new(pos:, size: calculated_size)

    Draw.rect(
      pos:,
      size: calculated_size,
      color: Color.regal_blue,
      anchor_percentage: Vector.new(0.5, 0.5),
    )
    y = rect.top + style.padding
    @elements.each do |el|
      dimensions = el.dimensions
      pos = Vector.new(@pos.x, (dimensions.y * 0.5) + y)
      y += style.padding + dimensions.y
      Draw.text(text: el.message, pos:, font: el.font, size: el.size, halign: :center)
    end
  end

  def dimensions; end

  private

  attr_reader :pos, :size, :padding
end

module ImUI
  def self.container
    c = ImUiContainer.new
    yield c
    c.draw
  end
end

class Demo
  attr_reader :volume, :pitch

  def initialize
    @ready = false
  end

  def tick
    setup unless ready?
    Engine.background_color = Color.crow_black_blue

    ImUI.container do |ui|
      ui.text('Immediate Mode GUI')
      ui.text('Immediate Mode GUI')
    end
  end

  def setup
    @ready = true
  end

  def ready?
    @ready
  end
end

$demo ||= Demo.new
$demo.tick
