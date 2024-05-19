# frozen_string_literal: true

module Bounds
  def bottom
    pos.y + (size.y * (1 - anchor_y))
  end

  def bottom=(value)
    pos.y = value - (size.y * (1 - anchor_y))
  end

  def top
    pos.y - (size.y * anchor_y)
  end

  def top=(value)
    pos.y = value + (size.y * anchor_y)
  end

  def left
    pos.x - (size.x * anchor_x)
  end

  def left=(value)
    pos.x = value + (size.x * anchor_x)
  end

  def right
    pos.x + (size.x * (1 - anchor_x))
  end

  def right=(value)
    pos.x = value - (size.x * (1 - anchor_x))
  end

  def inside?(point)
    point.x > left && point.x < right && point.y > top && point.y < bottom
  end

  def anchor_x
    anchor_percentage.x
  end

  def anchor_y
    anchor_percentage.y
  end

  def anchor_percentage
    Vector.new(0.5, 0.5)
  end
end

module DefinedAttribute
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.include(InstanceMethods)
  end

  module InstanceMethods
    attr_reader :attributes

    def initialize(**kwargs)
      @attributes = kwargs.to_h
    end

    def to_h
      self.class.all_attrs.each_with_object({}) do |attr, out|
        out[attr] = send(attr)
      end
    end
  end

  module ClassMethods
    def define_attr(method_name, default: nil)
      all_attrs << method_name
      create_getter(method_name, default)
    end

    def all_attrs
      @all_attrs ||= []
    end

    def create_getter(method_name, default_value)
      define_method(method_name) { attributes[method_name] || default_value }
    end
  end
end

class Timer
  attr_reader :time, :total_time

  def initialize(time = 0)
    @time = time
    @total_time = time
  end

  def tick
    return unless @time.positive?

    @time -= FrameInput.delta_time
  end

  def reset(new_time = nil)
    @total_time = new_time || total_time
    @time = total_time
  end

  def finished?
    @time <= 0
  end

  def percentage
    [1 - (@time / @total_time), 1].min
  end
end
