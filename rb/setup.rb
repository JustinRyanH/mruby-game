# frozen_string_literal: true

Vector.class_eval do
  def inspect
    { name: 'Vector', x: x, y: y }
  end
end

black = Color.new(0, 0, 0, 255)
