# frozen_string_literal: true

module Bounds
  def bottom
    pos.y + (size.y * 0.5)
  end

  def top
    pos.y - (size.y * 0.5)
  end

  def left
    pos.x - (size.x * 0.5)
  end

  def right
    pos.x + (size.x * 0.5)
  end
end

module FieldAccessor
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
      self.class.all_fields.each_with_object({}) do |field, out|
        out[field] = send(field)
      end
    end
  end

  module ClassMethods
    def field(method_name, default: nil)
      all_fields << method_name
      create_getter(method_name, default)
    end

    def all_fields
      @all_fields ||= []
    end

    def create_getter(method_name, default_value)
      define_method(method_name) { attributes[method_name] || default_value }
    end
  end
end
