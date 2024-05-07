# frozen_string_literal: true

# require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick
#
require 'assets/scripts/assets'

class ImUiText
  attr_reader :message, :pos, :size, :font

  def initialize(message, pos:)
    @message = message
    @pos = pos
    @size = 32
    @font = Fonts.kenney_future
  end

  def dimensions
    Draw.measure_text(text: message, size:, font:)
  end

  def draw; end
end

class ImUiContainer
  def initialize(
    size: Vector.new(100, 200),
    pos: Vector.new(*FrameInput.screen_size) * 0.5
  )
    @padding = 8
    @pos = pos
    @size = size
    @elements = []
  end

  def text(message)
    @elements << ImUiText.new(message, pos:)
  end

  def draw
    new_size = Vector.zero
    @elements.each do |el|
      dims = el.dimensions
      new_size.y += dims.y
      new_size.y += @padding
      new_size.x = [new_size.x, dims.x].max
    end
    new_size.x += @padding

    Draw.rect(
      pos:,
      size: new_size,
      color: Color.regal_blue,
      anchor_percentage: Vector.new(0.5, 0.5),
    )
    @elements.each do |el|
      Draw.text(text: el.message, pos: el.pos, font: el.font, size: el.size, halign: :center)
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
