// WAV file format validator

///|
/// Validation result with detailed error information.
pub struct ValidationResult {
  /// Whether the file is valid
  is_valid : Bool
  /// List of warnings (non-fatal issues)
  warnings : Array[String]
  /// Error message if invalid
  error : String?
} derive(Debug)

///|
/// Validate a WAV file and return detailed results.
///
/// Checks:
/// - RIFF header correctness
/// - WAVE marker presence
/// - fmt chunk structure and values
/// - data chunk presence
/// - Chunk alignment
/// - Data size consistency
///
/// # Arguments
/// * `data` - The raw bytes of the WAV file
///
/// # Returns
/// * `ValidationResult` - Detailed validation result
pub fn validate(data : Bytes) -> ValidationResult {
  let warnings = []

  // Check minimum file size (RIFF header = 12 bytes)
  if data.length() < 12 {
    return { is_valid: false, warnings, error: Some("File too small: minimum 12 bytes required") }
  }

  // Check RIFF header
  match data {
    [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'A', b'V', b'E', ..] => ()
    _ => return { is_valid: false, warnings, error: Some("Invalid RIFF/WAVE header") }
  }

  // Parse RIFF size
  let riff_size = parse_le_u32(data, 4)
  if riff_size + 8 != data.length() {
    warnings.push("RIFF size field does not match file size")
  }

  // Parse chunks
  let view = data[12:]
  let mut pos = 0
  let mut has_fmt = false
  let mut has_data = false
  let mut fmt_audio_format = 0
  let mut fmt_num_channels = 0
  let mut fmt_sample_rate = 0
  let mut fmt_bits_per_sample = 0
  let mut data_chunk_size = 0

  while pos + 8 <= view.length() {
    let chunk_id = [view[pos], view[pos + 1], view[pos + 2], view[pos + 3]]
    let chunk_size = parse_le_u32_from_view(view, pos + 4)

    if chunk_id == [b'f', b'm', b't', b' '] {
      has_fmt = true

      if chunk_size < 16 {
        return { is_valid: false, warnings, error: Some("fmt chunk too small: minimum 16 bytes") }
      }

      if pos + 8 + chunk_size > view.length() {
        return { is_valid: false, warnings, error: Some("fmt chunk extends beyond file") }
      }

      fmt_audio_format = parse_le_u16_from_view(view, pos + 8)
      fmt_num_channels = parse_le_u16_from_view(view, pos + 10)
      fmt_sample_rate = parse_le_u32_from_view(view, pos + 12)
      fmt_bits_per_sample = parse_le_u16_from_view(view, pos + 22)

      // Validate format values
      if fmt_audio_format != 1 && fmt_audio_format != 3 {
        warnings.push("Audio format is not PCM (1) or IEEE float (3)")
      }

      if fmt_num_channels < 1 {
        return { is_valid: false, warnings, error: Some("Invalid channel count: must be >= 1") }
      }

      if fmt_num_channels > 2 {
        warnings.push("More than 2 channels detected; only mono and stereo are fully supported")
      }

      if fmt_sample_rate < 1 {
        return { is_valid: false, warnings, error: Some("Invalid sample rate: must be >= 1") }
      }

      if fmt_sample_rate > 192000 {
        warnings.push("Sample rate exceeds 192000 Hz; this is unusual")
      }

      if fmt_audio_format == 1 {
        if fmt_bits_per_sample != 8 && fmt_bits_per_sample != 16 &&
          fmt_bits_per_sample != 24 && fmt_bits_per_sample != 32 {
          return { is_valid: false, warnings, error: Some("Unsupported PCM bit depth: must be 8, 16, 24, or 32") }
        }
      }

      if fmt_audio_format == 3 && fmt_bits_per_sample != 32 {
        return { is_valid: false, warnings, error: Some("IEEE float format requires 32 bits per sample") }
      }
    } else if chunk_id == [b'd', b'a', b't', b'a'] {
      has_data = true
      data_chunk_size = chunk_size

      if pos + 8 + chunk_size > view.length() {
        warnings.push("Data chunk extends beyond file; file may be truncated")
      }
    }

    // Move to next chunk (2-byte aligned)
    pos = pos + 8 + chunk_size
    if chunk_size % 2 != 0 {
      pos = pos + 1
    }
  }

  // Check required chunks
  if !has_fmt {
    return { is_valid: false, warnings, error: Some("Missing fmt chunk") }
  }

  if !has_data {
    return { is_valid: false, warnings, error: Some("Missing data chunk") }
  }

  // Validate data size vs format
  if has_fmt && has_data {
    let bytes_per_sample = fmt_bits_per_sample / 8
    let expected_frame_size = fmt_num_channels * bytes_per_sample
    if expected_frame_size > 0 && data_chunk_size % expected_frame_size != 0 {
      warnings.push("Data chunk size is not a multiple of frame size")
    }
  }

  { is_valid: true, warnings, error: None }
}

///|
/// Parse a little-endian 16-bit unsigned integer from BytesView.
fn parse_le_u16_from_view(view : BytesView, pos : Int) -> Int {
  view[pos].to_int() | (view[pos + 1].to_int() << 8)
}

///|
/// Parse a little-endian 32-bit unsigned integer from BytesView.
fn parse_le_u32_from_view(view : BytesView, pos : Int) -> Int {
  view[pos].to_int() |
    (view[pos + 1].to_int() << 8) |
    (view[pos + 2].to_int() << 16) |
    (view[pos + 3].to_int() << 24)
}

///|
/// Parse a little-endian 32-bit unsigned integer from Bytes.
fn parse_le_u32(data : Bytes, offset : Int) -> Int {
  let view = data[:]
  view[offset].to_int() |
    (view[offset + 1].to_int() << 8) |
    (view[offset + 2].to_int() << 16) |
    (view[offset + 3].to_int() << 24)
}
