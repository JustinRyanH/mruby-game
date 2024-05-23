# frozen_string_literal: true

# require 'assets/scripts/setup'
# h = {}
# ObjectSpace.count_objects(h)
# puts h

# $game ||= Game.new
# $game.tick

class Spring
  attr_reader :frequency, :damping, :params

  def initialize(frequency, damping)
    @frequency = frequency
    @damping = damping
    update_params
  end

  def frequency=(value)
    @frequency = value
    update_params
  end

  def damping=(value)
    @dampign = value
    update_params
  end

  def motion(current_pos, current_vel, target_pos)
    old_pos = current_pos - target_pos
    old_vel = current_vel

    out_pos = (old_pos * ppc) + (old_vel * pvc) + target_pos
    out_vel = (old_pos * vpc) + (old_vel * vvc)

    [out_pos, out_vel]
  end

  private

  def update_params
    @pos_pos_coef = 1.0
    @pos_vel_coef = 0.0

    @vel_pos_coef = 0.0
    @vel_vel_coef = 1.0
    setup(frequency, damping)

    @params = SpringParams.new
    @params.setup(frequency, damping)
  end

  def ppc
    @params.pos_pos_coef
  end

  def pvc
    @params.pos_vel_coef
  end

  def vpc
    @params.vel_pos_coef
  end

  def vvc
    @params.vel_vel_coef
  end

  def setup(freq, damping)
    dt = FrameInput.delta_time

    freq = [freq, 0.0].max.to_f
    damping = [damping, 0.0].max.to_f

    epsilon = 0.0001
    return if freq < epsilon

    if damping > 1 + epsilon
      za = -freq * damping
      zb = freq * Math.sqrt((damping * damping) - 1.0)
      z1 = za - zb
      z2 = za + zb

      e1 = Math.exp(z1 * dt)
      e2 = Math.exp(z2 * dt)

      inv_two_zb = 1.0 / (2.0 * zb)

      e1_over_two_zb = e1 * inv_two_zb
      e2_over_two_zb = e2 * inv_two_zb

      z1e1_over_two_zb = z1 * e1_over_two_zb
      z2e2_over_two_zb = z2 * e2_over_two_zb

      @pos_pos_coef = (e1_over_two_zb * z2) - z2e2_over_two_zb + e2
      @pos_vel_coef = -e1_over_two_zb + e2_over_two_zb

      @vel_pos_coef = (z1e1_over_two_zb - z2e2_over_two_zb + e2) * z2
      @vel_vel_coef = -z1e1_over_two_zb + z2e2_over_two_zb
    elsif damping < 1 - epsilon
      omega_zeta = freq * damping
      alpha = freq * Math.sqrt(1 - (damping * damping))

      exp_term = Math.exp(-omega_zeta * dt)
      cos_term = Math.cos(alpha * dt)
      sin_term = Math.sin(alpha * dt)

      inv_alpha = 1.0 / alpha

      exp_sin = exp_term * sin_term
      exp_cos = exp_term * cos_term
      exp_omega_zeta_sin_over_alpha = exp_term * omega_zeta * sin_term * inv_alpha

      @pos_pos_coef = exp_cos + exp_omega_zeta_sin_over_alpha
      @pos_vel_coef = exp_sin * inv_alpha

      @vel_pos_coef = (-exp_sin * alpha) - (omega_zeta * exp_omega_zeta_sin_over_alpha)
      @vel_vel_coef = exp_cos - exp_omega_zeta_sin_over_alpha
    else
      exp_term = Math.exp(-freq * dt)
      time_exp = dt * exp_term
      time_exp_freq = time_exp * freq

      @pos_pos_coef = time_exp_freq + exp_term
      @pos_vel_coef = time_exp

      @vel_pos_coef = -freq * time_exp_freq
      @vel_vel_coef = -time_exp_freq + exp_term
    end
  end
end

class SpringParams
  ##  /******************************************************************************
  ##  Copyright (c) 2008-2012 Ryan Juckett
  ##  http://www.ryanjuckett.com/
  ##
  ##  This software is provided 'as-is', without any express or implied
  ##  warranty. In no event will the authors be held liable for any damages
  ##  arising from the use of this software.
  ##
  ##  Permission is granted to anyone to use this software for any purpose,
  ##  including commercial applications, and to alter it and redistribute it
  ##  freely, subject to the following restrictions:
  ##
  ##  1. The origin of this software must not be misrepresented; you must not
  ##     claim that you wrote the original software. If you use this software
  ##     in a product, an acknowledgment in the product documentation would be
  ##     appreciated but is not required.
  ##
  ##  2. Altered source versions must be plainly marked as such, and must not be
  ##     misrepresented as being the original software.
  ##
  ##  3. This notice may not be removed or altered from any source
  ##     distribution.
  # #******************************************************************************/

  attr_reader :pos_pos_coef, :pos_vel_coef, :vel_pos_coef, :vel_vel_coef

  def initialize
    @pos_pos_coef = 1.0
    @pos_vel_coef = 0.0

    @vel_pos_coef = 0.0
    @vel_vel_coef = 1.0
  end

  def setup(freq, damping)
    dt = FrameInput.delta_time

    freq = [freq, 0.0].max.to_f
    damping = [damping, 0.0].max.to_f

    epsilon = 0.0001
    return if freq < epsilon

    if damping > 1 + epsilon
      za = -freq * damping
      zb = freq * Math.sqrt((damping * damping) - 1.0)
      z1 = za - zb
      z2 = za + zb

      e1 = Math.exp(z1 * dt)
      e2 = Math.exp(z2 * dt)

      inv_two_zb = 1.0 / (2.0 * zb)

      e1_over_two_zb = e1 * inv_two_zb
      e2_over_two_zb = e2 * inv_two_zb

      z1e1_over_two_zb = z1 * e1_over_two_zb
      z2e2_over_two_zb = z2 * e2_over_two_zb

      self.pos_pos_coef = (e1_over_two_zb * z2) - z2e2_over_two_zb + e2
      self.pos_vel_coef = -e1_over_two_zb + e2_over_two_zb

      self.vel_pos_coef = (z1e1_over_two_zb - z2e2_over_two_zb + e2) * z2
      self.vel_vel_coef = -z1e1_over_two_zb + z2e2_over_two_zb
    elsif damping < 1 - epsilon
      omega_zeta = freq * damping
      alpha = freq * Math.sqrt(1 - (damping * damping))

      exp_term = Math.exp(-omega_zeta * dt)
      cos_term = Math.cos(alpha * dt)
      sin_term = Math.sin(alpha * dt)

      inv_alpha = 1.0 / alpha

      exp_sin = exp_term * sin_term
      exp_cos = exp_term * cos_term
      exp_omega_zeta_sin_over_alpha = exp_term * omega_zeta * sin_term * inv_alpha

      self.pos_pos_coef = exp_cos + exp_omega_zeta_sin_over_alpha
      self.pos_vel_coef = exp_sin * inv_alpha

      self.vel_pos_coef = (-exp_sin * alpha) - (omega_zeta * exp_omega_zeta_sin_over_alpha)
      self.vel_vel_coef = exp_cos - exp_omega_zeta_sin_over_alpha
    else
      exp_term = Math.exp(-freq * dt)
      time_exp = dt * exp_term
      time_exp_freq = time_exp * freq

      self.pos_pos_coef = time_exp_freq + exp_term
      self.pos_vel_coef = time_exp

      self.vel_pos_coef = -freq * time_exp_freq
      self.vel_vel_coef = -time_exp_freq + exp_term
    end
  end

  def inspect
    {
      pos_pos_coef:,
      pos_vel_coef:,
      vel_pos_coef:,
      vel_vel_coef:
    }
  end

  private

  attr_writer :pos_pos_coef, :pos_vel_coef, :vel_pos_coef, :vel_vel_coef
end

class SpringEpxeriment
  def tick
    width, height = FrameInput.screen_size

    @frequency = 20
    @damping = 0.4

    Draw.text(text: 'Spring Example', size: 64, pos: Vector.new(width / 2, 70), color: Color.red, halign: :center)
    Draw.text(text: "FREQ: #{@frequency} DAMP: #{@damping}", size: 48, pos: Vector.new(width / 2, 150),
              color: Color.white, halign: :center)

    @spring_pos ||= Vector.new(width / 2, height / 2)
    @target_x ||= @spring_pos.x
    @spring_velocity ||= Vector.new(0, 0)
    @spring_min ||= 100
    @spring_max ||= width - 100
    @spring ||= Spring.new(@frequency, @damping)
    @spring.frequency = @frequency unless @frequency == @spring.frequency
    @spring.damping = @damping unless @damping == @spring.damping
    @spring_pos.x, @spring_velocity.x = @spring.motion(@spring_pos.x, @spring_velocity.x, @target_x)

    Draw.rect(pos: Vector.new(width / 2, height / 2), size: Vector.new(@spring_max - @spring_min, 8),
              color: Color.white)
    Draw.rect(pos: @spring_pos, size: Vector.new(75, 75))

    @target_x = FrameInput.mouse_pos.x.clamp(@spring_min, @spring_max) if FrameInput.mouse_just_pressed?(:left)
  end
end

$spring ||= SpringEpxeriment.new
$spring.tick
