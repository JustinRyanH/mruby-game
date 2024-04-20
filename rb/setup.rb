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

puts Color.ray_white.inspect

pos = Vector.new(45, 125)
size = Vector.new(100, 45)
color = Color.white

puts "Pos(#{pos}), Size(#{size}, Color(#{color}))"
Entity.create
