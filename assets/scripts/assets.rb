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

  def self.copter2
    @copter2 ||= AssetSystem.load_texture('assets/textures/copter_2.png')
  end

  def self.copter3
    @copter3 ||= AssetSystem.load_texture('assets/textures/copter_3.png')
  end
end
