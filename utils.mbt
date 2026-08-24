// Utility functions for WAV audio

///|
/// Format WAV info as a human-readable string.
pub fn format_wav_info(info : WavInfo) -> String {
  let format_str = match info.audio_format {
    1 => "PCM"
    3 => "IEEE Float"
    _ => "Unknown (" + info.audio_format.to_string() + ")"
  }
  let channel_str = match info.num_channels {
    1 => "Mono"
    2 => "Stereo"
    _ => info.num_channels.to_string() + " channels"
  }
  let duration = if info.byte_rate > 0 {
    Double::from_int(info.data_size) / Double::from_int(info.byte_rate)
  } else {
    0.0
  }

  "Format: " + format_str +
    "\nChannels: " + channel_str +
    "\nSample Rate: " + info.sample_rate.to_string() + " Hz" +
    "\nBits Per Sample: " + info.bits_per_sample.to_string() +
    "\nByte Rate: " + info.byte_rate.to_string() +
    "\nBlock Align: " + info.block_align.to_string() +
    "\nData Size: " + info.data_size.to_string() + " bytes" +
    "\nDuration: " + duration.to_string() + " seconds"
}

///|
/// Split stereo samples into left and right channels.
///
/// # Arguments
/// * `samples` - Interleaved stereo samples [L0, R0, L1, R1, ...]
///
/// # Returns
/// * `(Array[Int], Array[Int])` - (left_channel, right_channel)
pub fn split_stereo(samples : Array[Int]) -> (Array[Int], Array[Int]) {
  let left = []
  let right = []

  let mut i = 0
  while i + 1 < samples.length() {
    left.push(samples[i])
    right.push(samples[i + 1])
    i = i + 2
  }

  (left, right)
}

///|
/// Combine left and right channels into interleaved stereo samples.
///
/// # Arguments
/// * `left` - Left channel samples
/// * `right` - Right channel samples
///
/// # Returns
/// * `Array[Int]` - Interleaved stereo samples [L0, R0, L1, R1, ...]
pub fn combine_stereo(
  left : Array[Int],
  right : Array[Int],
) -> Array[Int] {
  let result = []
  let max_len = if left.length() > right.length() { left.length() } else { right.length() }

  let mut i = 0
  while i < max_len {
    let l = if i < left.length() { left[i] } else { 0 }
    let r = if i < right.length() { right[i] } else { 0 }
    result.push(l)
    result.push(r)
    i = i + 1
  }

  result
}

///|
/// Get the duration of audio in seconds.
pub fn get_duration(audio : AudioData) -> Double {
  if audio.info.byte_rate > 0 {
    Double::from_int(audio.info.data_size) / Double::from_int(audio.info.byte_rate)
  } else {
    0.0
  }
}

///|
/// Get the number of frames (samples per channel).
pub fn get_frame_count(audio : AudioData) -> Int {
  if audio.info.num_channels > 0 {
    audio.samples.length() / audio.info.num_channels
  } else {
    audio.samples.length()
  }
}

///|
/// Extract a single channel from multi-channel audio.
///
/// # Arguments
/// * `samples` - Interleaved multi-channel samples
/// * `num_channels` - Total number of channels
/// * `channel` - Channel index to extract (0-based)
///
/// # Returns
/// * `Array[Int]` - Extracted channel samples
pub fn extract_channel(
  samples : Array[Int],
  num_channels : Int,
  channel : Int,
) -> Array[Int] {
  let result = []

  let mut i = channel
  while i < samples.length() {
    result.push(samples[i])
    i = i + num_channels
  }

  result
}

///|
/// Mix multiple audio streams with equal weight.
///
/// # Arguments
/// * `streams` - Array of audio sample arrays
///
/// # Returns
/// * `Array[Int]` - Mixed samples
pub fn mix_multiple(streams : Array[Array[Int]]) -> Array[Int] {
  if streams.length() == 0 {
    return []
  }

  // Find max length
  let mut max_len = 0
  let mut i = 0
  while i < streams.length() {
    if streams[i].length() > max_len {
      max_len = streams[i].length()
    }
    i = i + 1
  }

  let result = []
  let count = Double::from_int(streams.length())

  let mut pos = 0
  while pos < max_len {
    let mut sum = 0.0
    let mut j = 0
    while j < streams.length() {
      if pos < streams[j].length() {
        sum = sum + Double::from_int(streams[j][pos])
      }
      j = j + 1
    }
    result.push((sum / count).to_int())
    pos = pos + 1
  }

  result
}

///|
/// Repeat audio samples a specified number of times.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `times` - Number of times to repeat
///
/// # Returns
/// * `Array[Int]` - Repeated samples
pub fn repeat(samples : Array[Int], times : Int) -> Array[Int] {
  let result = []

  let mut t = 0
  while t < times {
    let mut i = 0
    while i < samples.length() {
      result.push(samples[i])
      i = i + 1
    }
    t = t + 1
  }

  result
}

///|
/// Pad audio with silence to reach a target length.
///
/// # Arguments
/// * `samples` - Input audio samples
/// * `target_length` - Target number of samples
///
/// # Returns
/// * `Array[Int]` - Padded samples
pub fn pad_to_length(
  samples : Array[Int],
  target_length : Int,
) -> Array[Int] {
  let result = []

  let mut i = 0
  while i < target_length {
    if i < samples.length() {
      result.push(samples[i])
    } else {
      result.push(0)
    }
    i = i + 1
  }

  result
}

///|
/// Calculate the cross-correlation between two signals at zero lag.
/// Useful for comparing similarity of two audio signals.
pub fn cross_correlation_zero_lag(a : Array[Int], b : Array[Int]) -> Double {
  let len = if a.length() < b.length() { a.length() } else { b.length() }
  if len == 0 {
    return 0.0
  }

  let mut sum = 0.0
  let mut i = 0
  while i < len {
    sum = sum + Double::from_int(a[i]) * Double::from_int(b[i])
    i = i + 1
  }

  sum / Double::from_int(len)
}
