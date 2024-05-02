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

  def self.square
    @square ||= AssetSystem.load_texture('assets/textures/square.png')
  end

  def self.platform_top_middle
    @platform_top_middle ||= AssetSystem.load_texture('assets/textures/platform_um.png')
  end

  def self.platform_top_left
    @platform_top_left ||= AssetSystem.load_texture('assets/textures/platform_ulc.png')
  end

  def self.platform_top_right
    @platform_top_right ||= AssetSystem.load_texture('assets/textures/platform_urc.png')
  end

  def self.platform_middle
    @platform_middle ||= AssetSystem.load_texture('assets/textures/platform_m.png')
  end

  def self.platform_middle_left
    @platform_middle_left ||= AssetSystem.load_texture('assets/textures/platform_lm.png')
  end

  def self.platform_middle_right
    @platform_middle_right ||= AssetSystem.load_texture('assets/textures/platform_lm.png')
  end
end
