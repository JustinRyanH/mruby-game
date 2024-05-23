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
    @frequency = [frequency, 0.0].max.to_f
    @damping = [damping, 0.0].max.to_f

    @ppc = 1.0
    @pvc = 0.0

    @vpc = 0.0
    @vvc = 1.0

    update_params
  end

  def frequency=(value)
    @frequency = [value, 0.0].max.to_f
    update_params
  end

  def damping=(value)
    @damping = [value, 0.0].max.to_f
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

  attr_reader :ppc, :pvc, :vpc, :vvc

  def update_params
    epsilon = 0.0001
    if frequency < epsilon
      set_near_zero_coefficient
      return
    end

    if damping > 1 + epsilon
      over_one_coefficient
    elsif damping < 1 - epsilon
      under_one_coefficient
    else
      at_one_coefficient
    end
  end

  def set_near_zero_coefficient
    @ppc = 1.0
    @pvc = 0.0

    @vpc = 0.0
    @vvc = 1.0
  end

  def under_one_coefficient
    dt = FrameInput.delta_time

    omega_zeta = frequency * damping
    alpha = frequency * Math.sqrt(1 - (damping * damping))

    exp_term = Math.exp(-omega_zeta * dt)
    cos_term = Math.cos(alpha * dt)
    sin_term = Math.sin(alpha * dt)

    inv_alpha = 1.0 / alpha

    exp_sin = exp_term * sin_term
    exp_cos = exp_term * cos_term
    exp_omega_zeta_sin_over_alpha = exp_term * omega_zeta * sin_term * inv_alpha

    @ppc = exp_cos + exp_omega_zeta_sin_over_alpha
    @pvc = exp_sin * inv_alpha

    @vpc = (-exp_sin * alpha) - (omega_zeta * exp_omega_zeta_sin_over_alpha)
    @vvc = exp_cos - exp_omega_zeta_sin_over_alpha
  end

  def over_one_coefficient
    dt = FrameInput.delta_time

    za = -frequency * damping
    zb = frequency * Math.sqrt((damping * damping) - 1.0)
    z1 = za - zb
    z2 = za + zb

    e1 = Math.exp(z1 * dt)
    e2 = Math.exp(z2 * dt)

    inv_two_zb = 1.0 / (2.0 * zb)

    e1_over_two_zb = e1 * inv_two_zb
    e2_over_two_zb = e2 * inv_two_zb

    z1e1_over_two_zb = z1 * e1_over_two_zb
    z2e2_over_two_zb = z2 * e2_over_two_zb

    @ppc = (e1_over_two_zb * z2) - z2e2_over_two_zb + e2
    @pvc = -e1_over_two_zb + e2_over_two_zb

    @vpc = (z1e1_over_two_zb - z2e2_over_two_zb + e2) * z2
    @vvc = -z1e1_over_two_zb + z2e2_over_two_zb
  end

  def at_one_coefficient
    dt = FrameInput.delta_time

    exp_term = Math.exp(-frequency * dt)
    time_exp = dt * exp_term
    time_exp_freq = time_exp * frequency

    @ppc = time_exp_freq + exp_term
    @pvc = time_exp

    @vpc = -frequency * time_exp_freq
    @vvc = -time_exp_freq + exp_term
  end
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
    @target ||= @spring_pos.dup
    @spring_velocity ||= Vector.new(0, 0)
    @spring_min ||= 100
    @spring_max ||= width - 100
    @spring ||= Spring.new(@frequency, @damping)
    @spring.frequency = @frequency unless @frequency == @spring.frequency
    @spring.damping = @damping unless @damping == @spring.damping
    @spring_pos, @spring_velocity = @spring.motion(@spring_pos, @spring_velocity, @target)

    Draw.rect(pos: Vector.new(width / 2, height / 2), size: Vector.new(@spring_max - @spring_min, 8),
              color: Color.white)
    Draw.rect(pos: @spring_pos, size: Vector.new(75, 75))

    @target.x = FrameInput.mouse_pos.x.clamp(@spring_min, @spring_max) if FrameInput.mouse_just_pressed?(:left)
  end
end

$spring ||= SpringEpxeriment.new
$spring.tick
