# frozen_string_literal: true

Vector.class_eval do
  def inspect
    { name: 'Vector', x:, y: }
  end
end

Color.class_eval do
  def inspect
    { name: 'Color', red:, blue:, green:, alpha: }
  end
end

pos = Vector.new(45, 125)
size = Vector.new(100, 45)
color = Color.red

Entity.create(pos:, size:, color:)
