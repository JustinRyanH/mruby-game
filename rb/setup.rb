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

Entity.create(pos: Vector.new(45, 125), size: Vector.new(35, 75))
Entity.create(pos: Vector.new(300, 125), size: Vector.new(50, 66))
Entity.create(pos: Vector.new(700, 100), size: Vector.new(50, 66))
