# frozen_string_literal: true

require 'assets/scripts/engine_override'
require 'assets/scripts/assets'

class Style
  # @param [Float] padding
  # @param [Font] font
  # @param [Float] font_size
  attr_writer :padding, :font, :font_size, :font_color

  def self.from_hash(hsh)
    Style.new.tap do |style|
      hsh.keys
         .select { |k| style.respond_to?(:"#{k}=") }
         .each { |k| style.send(:"#{k}=", hsh[k]) }
    end
  end

  def padding
    @padding ||= 8
  end

  def font
    @font ||= Fonts.kenney_future
  end

  def font_size
    @font_size ||= 32
  end

  def font_color
    @font_color ||= Color.white
  end
end

class ImUiText
  extend ::Forwardable

  attr_reader :id, :message, :style

  def initialize(message, id: nil, style: Style.new)
    @message = message
    @id = id || Engine.hash_str(message)
    @style = style
  end

  def dimensions
    Draw.measure_text(text: message, size: style.font_size, font: style.font)
  end

  def draw; end

  def_delegators :@style, :padding, :font, :font_size
end

class ImUiContainer
  attr_reader :style

  def initialize(
    id:,
    size: Vector.new(100, 200),
    pos: Vector.new(*FrameInput.screen_size) * 0.5,
    style: Style.new
  )
    @id = Engine.hash_str(id.to_s)
    @style = style
    @pos = pos
    @size = size
    @elements = []
  end

  def text(message)
    @elements << ImUiText.new(message)
  end

  def draw
    rect = Rectangle.new(pos:, size: dimensions)

    Draw.rect(
      pos:,
      size: dimensions,
      color: Color.regal_blue,
      anchor_percentage: Vector.new(0.5, 0.5),
    )
    y = rect.top + style.padding
    @elements.each do |el|
      dimensions = el.dimensions
      pos = Vector.new(@pos.x, (dimensions.y * 0.5) + y)
      y += style.padding + dimensions.y
      Draw.text(text: el.message, pos:, font: el.font, size: el.font_size, halign: :center)
    end
  end

  def dimensions
    dimensions = @elements.map(&:dimensions)
    height = dimensions.inject(0) { |sum, dim| sum + dim.y + style.padding } + style.padding
    width = dimensions.inject(0) { |max, dim| [max, dim.x].max } + (style.padding * 2)

    Vector.new(width, height)
  end

  private

  attr_reader :pos, :size, :padding
end

class ImUI
  def self.ctx
    @@ctx ||= ImUI.new
  end

  def self.container(id)
    c = ImUiContainer.new(id:)
    yield c
    c.draw
  end
end
