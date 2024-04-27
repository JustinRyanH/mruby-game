# frozen_string_literal: true

class Fonts
  def self.kenney_future
    @kenney_future ||= AssetSystem.add_font('assets/fonts/Kenney Future.ttf')
  end
end

class Textures
  def self.copter
    @copter ||= AssetSystem.load_texture('assets/textures/copter_1.png')
  end
end
