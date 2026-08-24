// Format conversion functions for WAV audio data

///|
/// Convert audio samples from one bit depth to another.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `from_bits` - Source bit depth (8, 16, or 24)
/// * `to_bits` - Target bit depth (8, 16, or 24)
///
/// # Returns
/// * `Ok(Array[Int])` - Converted samples
/// * `Err(WavError)` - Error during conversion
pub fn convert_bit_depth(
  samples : Array[Int],
  from_bits : Int,
  to_bits : Int,
) -> Result[Array[Int], WavError] {
  if from_bits == to_bits {
    return Ok(samples)
  }

  // First normalize to 32-bit range
  let normalized = normalize_samples(samples, from_bits)

  // Then convert to target bit depth
  match to_bits {
    8 => denormalize_8bit(normalized)
    16 => denormalize_16bit(normalized)
    24 => denormalize_24bit(normalized)
    _ => Err(UnsupportedFormat)
  }
}

///|
/// Convert audio samples between mono and stereo.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `from_channels` - Source channel count (1 or 2)
/// * `to_channels` - Target channel count (1 or 2)
///
/// # Returns
/// * `Ok(Array[Int])` - Converted samples
/// * `Err(WavError)` - Error during conversion
pub fn convert_channels(
  samples : Array[Int],
  from_channels : Int,
  to_channels : Int,
) -> Result[Array[Int], WavError] {
  if from_channels == to_channels {
    return Ok(samples)
  }

  match (from_channels, to_channels) {
    (1, 2) => mono_to_stereo(samples)
    (2, 1) => stereo_to_mono(samples)
    _ => Err(UnsupportedFormat)
  }
}

///|
/// Resample audio data to a different sample rate using linear interpolation.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `from_rate` - Source sample rate in Hz
/// * `to_rate` - Target sample rate in Hz
/// * `num_channels` - Number of channels
///
/// # Returns
/// * `Array[Int]` - Resampled samples
pub fn resample(
  samples : Array[Int],
  from_rate : Int,
  to_rate : Int,
  num_channels : Int,
) -> Array[Int] {
  if from_rate == to_rate {
    return samples
  }

  let result = []
  let ratio = Double::from_int(from_rate) / Double::from_int(to_rate)
  let total_frames = samples.length() / num_channels
  let new_frames = (Double::from_int(total_frames) / ratio).to_int()

  let mut i = 0
  while i < new_frames {
    let src_pos = Double::from_int(i) * ratio
    let src_frame = src_pos.floor().to_int()
    let frac = src_pos - Double::from_int(src_frame)

    let mut ch = 0
    while ch < num_channels {
      let idx0 = src_frame * num_channels + ch
      let idx1 = (src_frame + 1) * num_channels + ch

      if idx0 >= 0 && idx1 < samples.length() {
        let s0 = Double::from_int(samples[idx0])
        let s1 = Double::from_int(samples[idx1])
        let interpolated = (s0 + (s1 - s0) * frac).to_int()
        result.push(interpolated)
      } else if idx0 >= 0 && idx0 < samples.length() {
        result.push(samples[idx0])
      } else {
        result.push(0)
      }

      ch = ch + 1
    }

    i = i + 1
  }

  result
}

///|
/// Normalize samples to [-1.0, 1.0] range.
fn normalize_samples(samples : Array[Int], from_bits : Int) -> Array[Double] {
  match from_bits {
    // 8-bit PCM is unsigned [0, 255], centered at 128
    8 => samples.map(fn(sample) { Double::from_int(sample - 128) / 128.0 })
    16 => samples.map(fn(sample) { Double::from_int(sample) / 32768.0 })
    24 => samples.map(fn(sample) { Double::from_int(sample) / 8388608.0 })
    32 => samples.map(fn(sample) { Double::from_int(sample) / 2147483648.0 })
    _ => samples.map(fn(sample) { Double::from_int(sample) })
  }
}

///|
/// Denormalize samples to 8-bit range.
fn denormalize_8bit(samples : Array[Double]) -> Result[Array[Int], WavError] {
  let result = []
  let mut i = 0
  while i < samples.length() {
    let scaled = (samples[i] * 128.0).round().to_int() + 128
    let clamped = if scaled < 0 {
      0
    } else if scaled > 255 {
      255
    } else {
      scaled
    }
    result.push(clamped)
    i = i + 1
  }
  Ok(result)
}

///|
/// Denormalize samples to 16-bit range.
fn denormalize_16bit(samples : Array[Double]) -> Result[Array[Int], WavError] {
  let result = []
  let mut i = 0
  while i < samples.length() {
    let scaled = (samples[i] * 32768.0).round().to_int()
    let clamped = if scaled < -32768 {
      -32768
    } else if scaled > 32767 {
      32767
    } else {
      scaled
    }
    result.push(clamped)
    i = i + 1
  }
  Ok(result)
}

///|
/// Denormalize samples to 24-bit range.
fn denormalize_24bit(samples : Array[Double]) -> Result[Array[Int], WavError] {
  let result = []
  let mut i = 0
  while i < samples.length() {
    let scaled = (samples[i] * 8388608.0).round().to_int()
    let clamped = if scaled < -8388608 {
      -8388608
    } else if scaled > 8388607 {
      8388607
    } else {
      scaled
    }
    result.push(clamped)
    i = i + 1
  }
  Ok(result)
}

///|
/// Convert mono to stereo by duplicating each sample.
fn mono_to_stereo(samples : Array[Int]) -> Result[Array[Int], WavError] {
  let result = []
  let mut i = 0
  while i < samples.length() {
    result.push(samples[i])
    result.push(samples[i])
    i = i + 1
  }
  Ok(result)
}

///|
/// Convert stereo to mono by averaging channels.
fn stereo_to_mono(samples : Array[Int]) -> Result[Array[Int], WavError] {
  let result = []
  let mut i = 0

  while i + 1 < samples.length() {
    let left = samples[i]
    let right = samples[i + 1]
    let mono = (left + right) / 2
    result.push(mono)
    i = i + 2
  }

  Ok(result)
}
