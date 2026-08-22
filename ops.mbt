// Audio operations for WAV audio data

///|
/// Trim audio samples to a specified range.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `start_sample` - Start index (inclusive)
/// * `end_sample` - End index (exclusive)
///
/// # Returns
/// * `Array[Int]` - Trimmed samples
pub fn trim(
  samples : Array[Int],
  start_sample : Int,
  end_sample : Int,
) -> Array[Int] {
  let result = []
  let actual_end = if end_sample > samples.length() {
    samples.length()
  } else {
    end_sample
  }
  let actual_start = if start_sample < 0 { 0 } else { start_sample }

  let mut i = actual_start
  while i < actual_end {
    result.push(samples[i])
    i = i + 1
  }

  result
}

///|
/// Concatenate two audio sample arrays.
///
/// # Arguments
/// * `a` - First audio samples
/// * `b` - Second audio samples
///
/// # Returns
/// * `Array[Int]` - Concatenated samples
pub fn concat(a : Array[Int], b : Array[Int]) -> Array[Int] {
  let result = []
  let mut i = 0
  while i < a.length() {
    result.push(a[i])
    i = i + 1
  }
  i = 0
  while i < b.length() {
    result.push(b[i])
    i = i + 1
  }
  result
}

///|
/// Adjust the volume of audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `factor` - Volume multiplier (1.0 = no change, 0.5 = half volume, 2.0 = double)
///
/// # Returns
/// * `Array[Int]` - Volume-adjusted samples
pub fn adjust_volume(samples : Array[Int], factor : Double) -> Array[Int] {
  let result = []
  let mut i = 0
  while i < samples.length() {
    let adjusted = (Double::from_int(samples[i]) * factor).to_int()
    result.push(adjusted)
    i = i + 1
  }
  result
}

///|
/// Mix two audio streams together by averaging.
///
/// # Arguments
/// * `a` - First audio samples
/// * `b` - Second audio samples
///
/// # Returns
/// * `Array[Int]` - Mixed samples (length = max(a.length, b.length))
pub fn mix(a : Array[Int], b : Array[Int]) -> Array[Int] {
  let result = []
  let max_len = if a.length() > b.length() { a.length() } else { b.length() }

  let mut i = 0
  while i < max_len {
    let sample_a = if i < a.length() { a[i] } else { 0 }
    let sample_b = if i < b.length() { b[i] } else { 0 }
    let mixed = (sample_a + sample_b) / 2
    result.push(mixed)
    i = i + 1
  }

  result
}

///|
/// Fade in audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `fade_samples` - Number of samples to fade in
///
/// # Returns
/// * `Array[Int]` - Samples with fade in applied
pub fn fade_in(samples : Array[Int], fade_samples : Int) -> Array[Int] {
  let result = []
  let fade_len = if fade_samples > samples.length() {
    samples.length()
  } else {
    fade_samples
  }

  let mut i = 0
  while i < samples.length() {
    if i < fade_len {
      let factor = Double::from_int(i) / Double::from_int(fade_len)
      let faded = (Double::from_int(samples[i]) * factor).to_int()
      result.push(faded)
    } else {
      result.push(samples[i])
    }
    i = i + 1
  }

  result
}

///|
/// Fade out audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `fade_samples` - Number of samples to fade out
///
/// # Returns
/// * `Array[Int]` - Samples with fade out applied
pub fn fade_out(samples : Array[Int], fade_samples : Int) -> Array[Int] {
  let result = []
  let fade_len = if fade_samples > samples.length() {
    samples.length()
  } else {
    fade_samples
  }
  let fade_start = samples.length() - fade_len

  let mut i = 0
  while i < samples.length() {
    if i >= fade_start {
      let factor = Double::from_int(samples.length() - 1 - i) /
        Double::from_int(fade_len)
      let faded = (Double::from_int(samples[i]) * factor).to_int()
      result.push(faded)
    } else {
      result.push(samples[i])
    }
    i = i + 1
  }

  result
}

///|
/// Reverse audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
///
/// # Returns
/// * `Array[Int]` - Reversed samples
pub fn reverse(samples : Array[Int]) -> Array[Int] {
  let result = []
  let len = samples.length()

  let mut i = 0
  while i < len {
    result.push(samples[len - 1 - i])
    i = i + 1
  }

  result
}

///|
/// Get the peak amplitude of audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
///
/// # Returns
/// * `Int` - Peak amplitude (absolute value)
pub fn get_peak_amplitude(samples : Array[Int]) -> Int {
  let mut peak = 0
  let mut i = 0
  while i < samples.length() {
    let abs_sample = if samples[i] < 0 { -samples[i] } else { samples[i] }
    if abs_sample > peak {
      peak = abs_sample
    }
    i = i + 1
  }
  peak
}

///|
/// Get the RMS (Root Mean Square) level of audio samples.
///
/// # Arguments
/// * `samples` - Input audio samples
///
/// # Returns
/// * `Double` - RMS level
pub fn get_rms_level(samples : Array[Int]) -> Double {
  if samples.length() == 0 {
    return 0.0
  }

  let mut sum_squares = 0.0
  let mut i = 0
  while i < samples.length() {
    let d = Double::from_int(samples[i])
    sum_squares = sum_squares + d * d
    i = i + 1
  }

  let mean = sum_squares / Double::from_int(samples.length())
  mean.sqrt()
}
