# frozen_string_literal: true

require 'assets/scripts/common'
require 'assets/scripts/engine_override'
require 'assets/scripts/assets'

class UiAction
  def initialize(element, &block)
    @element = element
    @block = block
  end

  def perform
    @block.call(@element)
  end
end

class Style
  # @param [Float] padding
  # @param [Font] font
  # @param [Float] font_size
  # @param [Color] font_color
  # @param [Color] background_color
  # @param [Symbol] text_align `:left`, `:right`, or `:center`
  attr_writer :padding, :font, :font_size, :font_color,
              :text_align, :background_color, :gap

  def self.from_hash(hsh)
    Style.new.tap { |style| style.merge_hash(hsh) }
  end

  def padding
    @padding ||= 4
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

  def gap
    @gap ||= 8
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
  include Bounds

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

  def track
    ctx.track_element(self)
  end

  def ctx
    ImUI.ctx
  end

  def dimensions
    raise 'All ImElements must provide `dimensions`'
  end

  def size
    dimensions
  end

  def draw
    raise 'All ImElements must be able to draw'
  end

  def focusable?
    false
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

class ImUiIcon < ImElement
  attr_accessor :size

  attr_reader :texture, :tint

  def initialize(size:, texture:, tint: Color.white, **)
    super(**)
    @size = size
    @texture = texture
    @tint = tint
  end

  alias dimensions size

  def draw
    Draw.texture(texture:, size:, pos:, tint:)
  end
end

class ImUiButton < ImElement
  attr_reader :message

  attr_writer :down

  def initialize(message:, pos: nil, id: nil, hover_style: nil, down_style: nil, **)
    super(id: id || Engine.hash_str(message), pos:, **)
    @message = message
    @hover_style = hover_style
    @down_style = down_style
  end

  def draw
    Draw.rect(
      pos:,
      size: dimensions,
      anchor_percentage: Vector.new(0.5, 0.5),
      color: current_style.background_color,
    )
    Draw.text(
      text: message,
      pos:,
      font: current_style.font,
      color: current_style.font_color,
      size: current_style.font_size,
      halign: current_style.text_align,
    )
  end

  def inside?(position)
    Rectangle.new(pos:, size: dimensions).inside?(position)
  end

  def dimensions
    Draw.measure_text(text: message, size: style.font_size, font: style.font) + (Vector.new(1, 1) * style.padding * 2)
  end

  def focus
    @focused = true
  end

  def focused?
    @focused ||= false
  end

  def focusable?
    true
  end

  def click
    @clicked = true
  end

  def clicked?
    @clicked || false
  end

  def hover?
    inside?(FrameInput.mouse_pos)
  end

  def down?
    @down || false
  end

  def current_style
    return down_style if down?
    return hover_style if hover?
    return hover_style if focused?

    style
  end

  def hover_style
    @hover_style ||= style
  end

  def down_style
    @down_style ||= hover_style
  end
end

class ImUiContainer < ImElement
  attr_accessor :focus_element

  # @param [Array<ImElement>] elements
  attr_reader :elements

  def initialize(pos:, min_size: Vector.new(0, 0), **)
    super(pos:, **)
    @min_size = min_size
    @actions = []
    @elements = []
    @focus_element = nil
  end

  def text(message, style: nil)
    ImUiText.new(message:, style: style.dup || self.style.dup).tap do |txt|
      @elements << txt
      update_positions
    end
  end

  def button(message, style: nil, **, &block)
    ImUiButton.new(message:, style: style.dup || self.style.dup, **).tap do |btn|
      @elements << btn
      update_positions
      @actions << UiAction.new(btn, &block)
    end
  end

  def <<(element)
    @elements << element
  end

  def focused?
    @elements.select(&:focusable?).any?(&:focused?)
  end

  def track
    ctx.track_element(self)
    @elements.each(&:track)
    @focus_element&.track
  end

  def perform
    @actions.each(&:perform)
  end

  def draw
    Draw.rect(
      pos:,
      size: dimensions,
      color: Color.regal_blue,
      anchor_percentage: Vector.new(0.5, 0.5),
    )

    @elements.each(&:draw)
    @focus_element&.draw if focused?
  end

  def dimensions
    dimensions = @elements.map(&:dimensions)
    height = dimensions.inject(0) { |sum, dim| sum + dim.y + style.gap }
    height = [min_size.y, height].max
    width = dimensions.inject(0) { |max, dim| [max, dim.x].max } + (style.padding * 2)
    width = [min_size.x, width].max

    Vector.new(width, height)
  end

  private

  def update_positions
    rect = Rectangle.new(pos:, size: dimensions)
    y = rect.top + style.padding
    @elements.each do |el|
      dimensions = el.dimensions
      el.pos = Vector.new(@pos.x, (dimensions.y * 0.5) + y)
      y += dimensions.y + style.gap
    end
  end

  attr_reader :pos, :min_size, :padding
end

class Transition
  # @param [Timer] timer
  attr_reader :origin, :target, :timer

  def initialize(origin, target, time: nil)
    @origin = origin
    @target = target
    @timer = time.nil? ? nil : Timer.new(time)
  end

  def target=(new_target)
    @target = new_target
    return if timer.nil?

    @origin = current_pos

    timer.reset([0.2 + timer.time, 0.4].min)
  end

  def update
    return target if timer.nil?

    timer.tick
    current_pos
  end

  def finished?
    return true if timer.nil?

    timer.finished?
  end

  private

  def current_pos
    origin.lerp(target, timer.percentage)
  end
end

class TrackedElement
  attr_reader :element, :last_frame

  def track(el)
    @element = el
    @last_frame = FrameInput.id

    handle_mouse_events
  end

  def handle_position
    if pos.nil?
      self.pos = element.pos
      self.last_pos = element.pos
    end

    return unless position_changed?

    self.pos = element.pos

    @pos_transition ||= Transition.new(last_pos, pos, time: 0.2)
    @pos_transition.target = pos if pos != @pos_transition.target
    element.pos = @pos_transition.update

    return unless @pos_transition.finished?

    self.last_pos = pos
    @pos_transition = nil
  end

  def focus
    return unless @element.respond_to?(:focus)

    @element.focus
  end

  def click
    return unless @element.respond_to?(:click)

    @element.click
  end

  def down
    return unless @element.respond_to?(:down=)

    @element.down = true
  end

  def focusable?
    @element.focusable?
  end

  private

  attr_accessor :pos, :last_pos

  def position_changed?
    last_pos != element.pos
  end

  def handle_mouse_events
    handle_click

    @mouse_down_frame = nil unless FrameInput.mouse_down?(:left)
    element.down = true if @mouse_down_frame&.positive?
  end

  def handle_click
    return unless element.respond_to?(:inside?)
    return unless element.inside?(FrameInput.mouse_pos)

    if FrameInput.mouse_down?(:left)
      @mouse_down_frame = FrameInput.id
      ctx.focused_element = self if ctx.focused_element != self
    end
    element.click if FrameInput.mouse_was_down?(:left) && @mouse_down_frame == FrameInput.id - 1
  end

  # @return [ImUI]
  def ctx
    ImUI.ctx
  end
end

class ImUI
  # @return [TrackedElement, nil] focused_element
  attr_accessor :focused_element
  attr_reader :root_elements

  # @return [TrackedElement, nil] focused_element

  def self.ctx
    @@ctx ||= ImUI.new
  end

  def self.update
    ctx.update
  end

  def self.draw
    ctx.draw
  end

  def self.container(id, **)
    c = ImUiContainer.new(id:, **)
    yield c
    ctx.root_elements << c
  end

  def initialize
    @tracked_elements = {}
    @root_elements = []
    @focused_element = nil
  end

  def track_element(element)
    @tracked_elements[element.id] = TrackedElement.new unless @tracked_elements.key?(element.id)
    @tracked_elements[element.id].track(element)
  end

  def update
    @root_elements.each(&:track)
    focus_element
    @root_elements.each(&:perform)
    @tracked_elements.each_value(&:handle_position)
  end

  def draw
    @root_elements.each(&:draw)
    @root_elements.clear
  end

  private

  def focus_element
    focusable_elements = @tracked_elements.values.select(&:focusable?)
    return nil if focusable_elements.empty?

    @focused_element = focusable_elements.first if @focused_element.nil?
    return if @focused_element.nil?

    move_focus_down(focusable_elements) if FrameInput.key_was_down?(:down)
    move_focus_up(focusable_elements) if FrameInput.key_was_down?(:up)
    @focused_element.down if %i[enter space].any? { |k| FrameInput.key_down?(k) }
    @focused_element.click if %i[enter space].any? { |k| FrameInput.key_was_down?(k) }

    @focused_element.focus
  end

  def move_focus_down(focusable)
    idx = focusable.find_index(@focused_element)
    next_element_idx = [idx + 1, focusable.size - 1].min
    @focused_element = focusable[next_element_idx]
  end

  def move_focus_up(focusable)
    return if @focused_element.nil?

    idx = focusable.find_index(@focused_element)
    next_element_idx = [idx - 1, 0].max
    @focused_element = focusable[next_element_idx]
  end
end
