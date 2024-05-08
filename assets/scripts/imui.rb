# frozen_string_literal: true

require 'assets/scripts/engine_override'
require 'assets/scripts/assets'

class Style
  # @param [Float] padding
  # @param [Font] font
  # @param [Float] font_size
  # @param [Color] font_color
  # @param [Symbol] text_align `:left`, `:right`, or `:center`
  attr_writer :padding, :font, :font_size, :font_color, :text_align

  def self.from_hash(hsh)
    Style.new.tap { |style| style.merge_hash(hsh) }
  end

  def padding
    @padding ||= 2
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

  def background_color
    @background_color ||= Color.blank
  end

  def text_align
    @text_align ||= :center
  end

  def merge(style)
    merge_hash(style.to_h)
  end

  def merge_hash(hsh)
    hsh.keys
       .select { |k| respond_to?(:"#{k}=") }
       .each { |k| send(:"#{k}=", hsh[k]) }
  end

  def to_h
    {
      padding:,
      font:,
      font_color:,
      font_size:,
      background_color:
    }
  end
end

class ImElement
  # @param [Vector] pos
  attr_accessor :pos

  # @return [Integer] id
  # @return [Style] style
  attr_reader :id, :style

  def initialize(id:, pos:, style: Style.new)
    @id = Engine.hash_str(id.to_s)
    @style = style
    @pos = pos
  end

  def dimensions
    raise 'All ImElements must provide `dimensions`'
  end

  def draw
    raise 'All ImElements must be able to draw'
  end
end

class ImUiText < ImElement
  # @return [String] message
  attr_reader :message

  def initialize(message:, pos: nil, id: nil, **)
    super(id: id || Engine.hash_str(message), pos:, **)
    @message = message
  end

  def dimensions
    Draw.measure_text(text: message, size: style.font_size, font: style.font) + (Vector.new(1, 1) * style.padding * 2)
  end

  def draw
    Draw.text(
      text: message,
      pos:,
      font: style.font,
      color: style.font_color,
      size: style.font_size,
      halign: style.text_align,
    )
  end
end

class ImUiContainer < ImElement
  def initialize(
    size: Vector.new(100, 200),
    pos: Vector.new(*FrameInput.screen_size) * 0.5,
    **
  )
    super(pos:, **)
    @pos = pos
    @size = size
    @elements = []
  end

  def text(message, style: nil)
    txt_style = self.style.clone
    txt_style.merge(style) unless style.nil?
    @elements << ImUiText.new(message:, style: txt_style)
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
      el.pos = Vector.new(@pos.x, (dimensions.y * 0.5) + y)
      el.draw
      y += style.padding + dimensions.y
    end
  end

  def dimensions
    dimensions = @elements.map(&:dimensions)
    height = dimensions.inject(0) { |sum, dim| sum + dim.y } + (style.padding * 2)
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

  def self.container(id, style: Style.new)
    c = ImUiContainer.new(id:, style:)
    yield c
    c.draw
  end

  def initialize
    @elements = {}
  end

  def track_element(element); end
end
