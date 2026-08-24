// Audio analysis functions

///|
/// Result of audio analysis.
pub struct AudioAnalysis {
  /// Duration in seconds
  duration_sec : Double
  /// Number of samples per channel
  samples_per_channel : Int
  /// Peak amplitude (absolute value)
  peak : Int
  /// RMS level
  rms : Double
  /// DC offset (mean value)
  dc_offset : Double
  /// Number of zero crossings
  zero_crossings : Int
  /// Whether clipping was detected
  has_clipping : Bool
  /// Number of clipped samples
  clipped_samples : Int
  /// Whether silence was detected (below threshold)
  is_silent : Bool
  /// Ratio of silent samples (0.0 to 1.0)
  silence_ratio : Double
} derive(Debug)

///|
/// Analyze audio samples and return comprehensive statistics.
///
/// # Arguments
/// * `audio` - The audio data to analyze
/// * `silence_threshold` - Amplitude threshold below which is considered silent (default: 100)
///
/// # Returns
/// * `AudioAnalysis` - Comprehensive analysis result
pub fn analyze(audio : AudioData, silence_threshold : Int) -> AudioAnalysis {
  let samples = audio.samples
  let info = audio.info

  let duration_sec = Double::from_int(info.data_size) /
    Double::from_int(info.byte_rate)
  let samples_per_channel = if info.num_channels > 0 {
    samples.length() / info.num_channels
  } else {
    samples.length()
  }

  // Peak amplitude
  let peak = get_peak_amplitude(samples)

  // RMS level
  let rms = get_rms_level(samples)

  // DC offset (mean)
  let dc_offset = calculate_dc_offset(samples)

  // Zero crossings
  let zero_crossings = count_zero_crossings(samples)

  // Clipping detection
  let max_val = match info.bits_per_sample {
    8 => 127
    16 => 32767
    24 => 8388607
    32 => 2147483647
    _ => 32767
  }
  let min_val = -max_val - 1
  let clipped = count_clipped_samples(samples, min_val, max_val)
  let has_clipping = clipped > 0

  // Silence detection
  let silent_count = count_silent_samples(samples, silence_threshold)
  let silence_ratio = if samples.length() > 0 {
    Double::from_int(silent_count) / Double::from_int(samples.length())
  } else {
    1.0
  }
  let is_silent = silence_ratio > 0.95

  {
    duration_sec,
    samples_per_channel,
    peak,
    rms,
    dc_offset,
    zero_crossings,
    has_clipping,
    clipped_samples: clipped,
    is_silent,
    silence_ratio,
  }
}

///|
/// Calculate the DC offset (mean value) of audio samples.
pub fn calculate_dc_offset(samples : Array[Int]) -> Double {
  if samples.length() == 0 {
    return 0.0
  }

  let mut sum = 0.0
  let mut i = 0
  while i < samples.length() {
    sum = sum + Double::from_int(samples[i])
    i = i + 1
  }
  sum / Double::from_int(samples.length())
}

///|
/// Count the number of zero crossings in the audio signal.
/// A zero crossing occurs when consecutive samples have different signs.
pub fn count_zero_crossings(samples : Array[Int]) -> Int {
  let mut count = 0
  let mut i = 1
  while i < samples.length() {
    if (samples[i - 1] >= 0 && samples[i] < 0) ||
      (samples[i - 1] < 0 && samples[i] >= 0) {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
/// Count the number of clipped samples (at min or max value).
pub fn count_clipped_samples(
  samples : Array[Int],
  min_val : Int,
  max_val : Int,
) -> Int {
  let mut count = 0
  let mut i = 0
  while i < samples.length() {
    if samples[i] <= min_val || samples[i] >= max_val {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
/// Count the number of silent samples (absolute value below threshold).
pub fn count_silent_samples(
  samples : Array[Int],
  threshold : Int,
) -> Int {
  let mut count = 0
  let mut i = 0
  while i < samples.length() {
    let abs_val = if samples[i] < 0 { -samples[i] } else { samples[i] }
    if abs_val < threshold {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
/// Format audio analysis as a human-readable string.
pub fn format_analysis(analysis : AudioAnalysis) -> String {
  let lines = []
  lines.push("=== Audio Analysis ===")
  lines.push("Duration: " + analysis.duration_sec.to_string() + " seconds")
  lines.push("Samples per channel: " + analysis.samples_per_channel.to_string())
  lines.push("Peak amplitude: " + analysis.peak.to_string())
  lines.push("RMS level: " + analysis.rms.to_string())
  lines.push("DC offset: " + analysis.dc_offset.to_string())
  lines.push("Zero crossings: " + analysis.zero_crossings.to_string())
  lines.push(
    "Clipping: " + (if analysis.has_clipping { "YES (" + analysis.clipped_samples.to_string() + " samples)" } else { "No" }),
  )
  lines.push(
    "Silence: " + (if analysis.is_silent { "YES" } else { "No" }) +
      " (" + (analysis.silence_ratio * 100.0).to_string() + "%)",
  )

  // Concatenate all lines
  let mut result = ""
  let mut i = 0
  while i < lines.length() {
    if i > 0 {
      result = result + "\n"
    }
    result = result + lines[i]
    i = i + 1
  }
  result
}
