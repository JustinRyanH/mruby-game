# frozen_string_literal: true

# h = {}
# ObjectSpace.count_objects(h)
# puts h
game = Game.current
game.tick

text = 'Really, Really Long Text'

ImUI.draw_rect(left: 50, right: 450, top: 50, bottom: 140, color: Color.orange)
ImUI.draw_text(text:, pos: Vector.new(60, 50 + 12), size: 24, color: Color.black, alignment: :left)
ImUI.draw_text(text:, pos: Vector.new(450 - 12, 50 + 36), size: 24, color: Color.black, alignment: :right)
ImUI.draw_text(text:, pos: Vector.new(50 + ((450 - 50) * 0.5), 50 + 36 + 24), size: 24, color: Color.black,
               alignment: :center)
