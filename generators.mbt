// Audio waveform generators

///|
/// Generate a sine wave.
///
/// # Arguments
/// * `frequency` - Frequency in Hz
/// * `amplitude` - Peak amplitude (e.g., 16000 for 16-bit)
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
///
/// # Returns
/// * `Array[Int]` - Generated samples
pub fn generate_sine(
  frequency : Double,
  amplitude : Double,
  sample_rate : Int,
  duration_sec : Double,
) -> Array[Int] {
  let num_samples = (Double::from_int(sample_rate) * duration_sec).to_int()
  let samples = []
  let pi = 3.141592653589793
  let two_pi = 2.0 * pi

  let mut i = 0
  while i < num_samples {
    let t = Double::from_int(i) / Double::from_int(sample_rate)
    let angle = two_pi * frequency * t

    // Reduce angle to [0, 2*pi) range
    let reduced = angle - two_pi * (angle / two_pi).floor()

    // Use symmetry: reduce to [0, pi/2] quadrant
    let (x, sign) = if reduced < pi {
      if reduced < pi / 2.0 {
        (reduced, 1.0)
      } else {
        (pi - reduced, 1.0)
      }
    } else if reduced < 3.0 * pi / 2.0 {
      (reduced - pi, -1.0)
    } else {
      (two_pi - reduced, -1.0)
    }

    // Taylor series for sin(x) in [0, pi/2] with 6 terms
    let x2 = x * x
    let sin_val = x *
      (
        1.0 -
        x2 *
        (
          1.0 / 6.0 -
          x2 *
          (
            1.0 / 120.0 -
            x2 * (1.0 / 5040.0 - x2 * (1.0 / 362880.0 - x2 / 39916800.0))
          )
        )
      )

    let sample = (amplitude * sign * sin_val).to_int()
    samples.push(sample)
    i = i + 1
  }

  samples
}

///|
/// Generate a square wave.
///
/// # Arguments
/// * `frequency` - Frequency in Hz
/// * `amplitude` - Peak amplitude
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
///
/// # Returns
/// * `Array[Int]` - Generated samples
pub fn generate_square(
  frequency : Double,
  amplitude : Double,
  sample_rate : Int,
  duration_sec : Double,
) -> Array[Int] {
  let num_samples = (Double::from_int(sample_rate) * duration_sec).to_int()
  let samples = []
  let period = Double::from_int(sample_rate) / frequency

  let mut i = 0
  while i < num_samples {
    let phase = Double::from_int(i) % period / period
    let sample = if phase < 0.5 { amplitude } else { -amplitude }
    samples.push(sample.to_int())
    i = i + 1
  }

  samples
}

///|
/// Generate a sawtooth wave.
///
/// # Arguments
/// * `frequency` - Frequency in Hz
/// * `amplitude` - Peak amplitude
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
///
/// # Returns
/// * `Array[Int]` - Generated samples
pub fn generate_sawtooth(
  frequency : Double,
  amplitude : Double,
  sample_rate : Int,
  duration_sec : Double,
) -> Array[Int] {
  let num_samples = (Double::from_int(sample_rate) * duration_sec).to_int()
  let samples = []
  let period = Double::from_int(sample_rate) / frequency

  let mut i = 0
  while i < num_samples {
    let phase = Double::from_int(i) % period / period
    let sample = amplitude * (2.0 * phase - 1.0)
    samples.push(sample.to_int())
    i = i + 1
  }

  samples
}

///|
/// Generate a triangle wave.
///
/// # Arguments
/// * `frequency` - Frequency in Hz
/// * `amplitude` - Peak amplitude
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
///
/// # Returns
/// * `Array[Int]` - Generated samples
pub fn generate_triangle(
  frequency : Double,
  amplitude : Double,
  sample_rate : Int,
  duration_sec : Double,
) -> Array[Int] {
  let num_samples = (Double::from_int(sample_rate) * duration_sec).to_int()
  let samples = []
  let period = Double::from_int(sample_rate) / frequency

  let mut i = 0
  while i < num_samples {
    let phase = Double::from_int(i) % period / period
    let sample = if phase < 0.5 {
      amplitude * (4.0 * phase - 1.0)
    } else {
      amplitude * (3.0 - 4.0 * phase)
    }
    samples.push(sample.to_int())
    i = i + 1
  }

  samples
}

///|
/// Generate white noise.
///
/// # Arguments
/// * `amplitude` - Peak amplitude
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
/// * `seed` - Random seed for reproducibility
///
/// # Returns
/// * `Array[Int]` - Generated samples
pub fn generate_noise(
  amplitude : Double,
  sample_rate : Int,
  duration_sec : Double,
  seed : Int,
) -> Array[Int] {
  let num_samples = (Double::from_int(sample_rate) * duration_sec).to_int()
  let samples = []

  // Simple linear congruential generator
  let mut state = seed.abs()

  let mut i = 0
  while i < num_samples {
    // LCG: state = (state * 1103515245 + 12345) & 0x7FFFFFFF
    state = ((state * 1103515245 + 12345) & 0x7FFFFFFF).abs()
    // Map to [-amplitude, amplitude]
    let normalized = (Double::from_int(state) / 1073741824.0 - 1.0) * amplitude
    samples.push(normalized.to_int())
    i = i + 1
  }

  samples
}

///|
/// Generate a chirp (frequency sweep) from start_freq to end_freq.
///
/// # Arguments
/// * `start_freq` - Starting frequency in Hz
/// * `end_freq` - Ending frequency in Hz
/// * `amplitude` - Peak amplitude
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
///
/// # Returns
/// * `Array[Int]` - Generated samples
pub fn generate_chirp(
  start_freq : Double,
  end_freq : Double,
  amplitude : Double,
  sample_rate : Int,
  duration_sec : Double,
) -> Array[Int] {
  let num_samples = (Double::from_int(sample_rate) * duration_sec).to_int()
  let samples = []
  let pi = 3.141592653589793
  let two_pi = 2.0 * pi
  let t_total = duration_sec

  let mut i = 0
  while i < num_samples {
    let t = Double::from_int(i) / Double::from_int(sample_rate)
    // Phase = integral of 2*pi*freq(t) dt
    let phase = two_pi *
      (start_freq * t + (end_freq - start_freq) * t * t / (2.0 * t_total))

    // Reduce angle to [0, 2*pi) and use symmetry
    let reduced = phase - two_pi * (phase / two_pi).floor()
    let (x, sign) = if reduced < pi {
      if reduced < pi / 2.0 {
        (reduced, 1.0)
      } else {
        (pi - reduced, 1.0)
      }
    } else if reduced < 3.0 * pi / 2.0 {
      (reduced - pi, -1.0)
    } else {
      (two_pi - reduced, -1.0)
    }
    let x2 = x * x
    let sin_val = x *
      (1.0 - x2 * (1.0 / 6.0 - x2 * (1.0 / 120.0 - x2 / 5040.0)))

    let sample = (amplitude * sign * sin_val).to_int()
    samples.push(sample)
    i = i + 1
  }

  samples
}

///|
/// Generate silence (all zeros).
///
/// # Arguments
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
///
/// # Returns
/// * `Array[Int]` - Generated samples (all zeros)
pub fn generate_silence(sample_rate : Int, duration_sec : Double) -> Array[Int] {
  let num_samples = (Double::from_int(sample_rate) * duration_sec).to_int()
  let samples = []

  let mut i = 0
  while i < num_samples {
    samples.push(0)
    i = i + 1
  }

  samples
}

///|
/// Generate a sine wave and return as AudioData ready for encoding.
///
/// # Arguments
/// * `frequency` - Frequency in Hz
/// * `amplitude` - Peak amplitude
/// * `sample_rate` - Sample rate in Hz
/// * `duration_sec` - Duration in seconds
/// * `bits_per_sample` - Bit depth (8, 16, 24, 32)
///
/// # Returns
/// * `AudioData` - Audio data ready for encoding
pub fn generate_sine_wav(
  frequency : Double,
  amplitude : Double,
  sample_rate : Int,
  duration_sec : Double,
  bits_per_sample : Int,
) -> AudioData {
  let samples = generate_sine(frequency, amplitude, sample_rate, duration_sec)
  let bytes_per_sample = bits_per_sample / 8
  let byte_rate = sample_rate * bytes_per_sample
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate,
    byte_rate,
    block_align: bytes_per_sample,
    bits_per_sample,
    data_size: samples.length() * bytes_per_sample,
  }
  { samples, info }
}
