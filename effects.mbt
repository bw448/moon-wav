// Audio effects processing

///|
/// Apply echo effect to audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `delay_samples` - Delay in samples (e.g., 4410 for 100ms at 44100Hz)
/// * `decay` - Decay factor for echo (0.0 to 1.0, e.g., 0.5)
///
/// # Returns
/// * `Array[Int]` - Samples with echo applied
pub fn echo(
  samples : Array[Int],
  delay_samples : Int,
  decay : Double,
) -> Array[Int] {
  let result = []
  let len = samples.length()

  let mut i = 0
  while i < len {
    let original = Double::from_int(samples[i])
    let echoed = if i >= delay_samples {
      Double::from_int(result[i - delay_samples]) * decay
    } else {
      0.0
    }
    let mixed = original + echoed
    result.push(mixed.to_int())
    i = i + 1
  }

  result
}

///|
/// Apply delay effect to audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `delay_samples` - Delay in samples
/// * `mix` - Mix ratio (0.0 = dry only, 1.0 = wet only, 0.5 = equal mix)
///
/// # Returns
/// * `Array[Int]` - Samples with delay applied
pub fn delay(
  samples : Array[Int],
  delay_samples : Int,
  mix : Double,
) -> Array[Int] {
  let result = []
  let len = samples.length()
  let dry = 1.0 - mix

  let mut i = 0
  while i < len {
    let original = Double::from_int(samples[i])
    let delayed = if i >= delay_samples {
      Double::from_int(samples[i - delay_samples])
    } else {
      0.0
    }
    let mixed = original * dry + delayed * mix
    result.push(mixed.to_int())
    i = i + 1
  }

  result
}

///|
/// Normalize audio to a target peak amplitude.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `target_peak` - Target peak amplitude (e.g., 32000 for 16-bit)
///
/// # Returns
/// * `Array[Int]` - Normalized samples
pub fn normalize(samples : Array[Int], target_peak : Int) -> Array[Int] {
  let current_peak = get_peak_amplitude(samples)
  if current_peak == 0 {
    return samples
  }

  let factor = Double::from_int(target_peak) / Double::from_int(current_peak)
  adjust_volume(samples, factor)
}

///|
/// Apply soft clipping to prevent harsh distortion.
/// Uses a tanh-like curve to smoothly limit amplitude.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `threshold` - Clipping threshold (e.g., 30000 for 16-bit)
///
/// # Returns
/// * `Array[Int]` - Samples with soft clipping applied
pub fn soft_clip(samples : Array[Int], threshold : Int) -> Array[Int] {
  let result = []
  let t = Double::from_int(threshold)

  let mut i = 0
  while i < samples.length() {
    let x = Double::from_int(samples[i]) / t
    // Approximation of tanh(x) for soft clipping
    let clipped = if x > 1.0 {
      1.0
    } else if x < -1.0 {
      -1.0
    } else {
      x - x * x * x / 3.0
    }
    result.push((clipped * t).to_int())
    i = i + 1
  }

  result
}

///|
/// Remove DC offset from audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
///
/// # Returns
/// * `Array[Int]` - Samples with DC offset removed
pub fn remove_dc_offset(samples : Array[Int]) -> Array[Int] {
  let dc = calculate_dc_offset(samples)
  let result = []

  let mut i = 0
  while i < samples.length() {
    let corrected = Double::from_int(samples[i]) - dc
    result.push(corrected.to_int())
    i = i + 1
  }

  result
}

///|
/// Apply a simple low-pass filter (moving average).
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `window_size` - Size of the moving average window (must be odd)
///
/// # Returns
/// * `Array[Int]` - Filtered samples
pub fn low_pass_filter(samples : Array[Int], window_size : Int) -> Array[Int] {
  let result = []
  let len = samples.length()
  let half = window_size / 2

  let mut i = 0
  while i < len {
    let mut sum = 0
    let mut count = 0
    let mut j = i - half
    while j <= i + half {
      if j >= 0 && j < len {
        sum = sum + samples[j]
        count = count + 1
      }
      j = j + 1
    }
    result.push(sum / count)
    i = i + 1
  }

  result
}

///|
/// Apply a simple high-pass filter (difference from moving average).
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `window_size` - Size of the moving average window
///
/// # Returns
/// * `Array[Int]` - Filtered samples
pub fn high_pass_filter(samples : Array[Int], window_size : Int) -> Array[Int] {
  let low_passed = low_pass_filter(samples, window_size)
  let result = []

  let mut i = 0
  while i < samples.length() {
    result.push(samples[i] - low_passed[i])
    i = i + 1
  }

  result
}

///|
/// Reverse audio and apply fade (creates a "reverse reverb" effect).
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `fade_samples` - Number of samples for fade
///
/// # Returns
/// * `Array[Int]` - Processed samples
pub fn reverse_reverb(samples : Array[Int], fade_samples : Int) -> Array[Int] {
  let reversed = reverse(samples)
  fade_in(reversed, fade_samples)
}
