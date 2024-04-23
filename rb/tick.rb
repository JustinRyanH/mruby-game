# frozen_string_literal: true

# h = {}
# ObjectSpace.count_objects(h)
# puts h
game = Game.current
game.tick

text = 'Really, Really Long Text'

ImUI.draw_text(text:, pos: Vector.new(200, 260), size: 24, color: Color.pink, alignment: :left)
ImUI.draw_text(text:, pos: Vector.new(200, 320), size: 24, color: Color.pink, alignment: :center)
ImUI.draw_text(text:, pos: Vector.new(300, 200), size: 24, color: Color.pink, alignment: :right)
