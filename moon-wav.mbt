// moon-wav: A MoonBit WAV audio decoding library
//
// This library provides:
// - WAV file parsing (RIFF header, fmt chunk, data chunk)
// - PCM audio decoding (8-bit, 16-bit, 24-bit)
// - Format conversion (bit depth, channels, sample rate)
// - Audio operations (trim, concat, volume adjust, mix)

///|
/// Represents the format information of a WAV file.
pub struct WavInfo {
  /// Audio format: 1 = PCM, 3 = IEEE float
  audio_format : Int
  /// Number of channels: 1 = mono, 2 = stereo
  num_channels : Int
  /// Sample rate in Hz (e.g., 44100)
  sample_rate : Int
  /// Byte rate (SampleRate * NumChannels * BitsPerSample/8)
  byte_rate : Int
  /// Block align (NumChannels * BitsPerSample/8)
  block_align : Int
  /// Bits per sample (8, 16, or 24)
  bits_per_sample : Int
  /// Size of the audio data in bytes
  data_size : Int
} derive(Debug)

///|
/// Represents decoded audio data with format information.
pub struct AudioData {
  /// Decoded audio samples (normalized to 32-bit signed integers)
  samples : Array[Int]
  /// Format information
  info : WavInfo
} derive(Debug)

///|
/// Errors that can occur during WAV decoding.
pub enum WavError {
  /// Invalid RIFF header
  InvalidHeader
  /// Unsupported audio format (not PCM)
  UnsupportedFormat
  /// Corrupted or truncated data
  CorruptedData
  /// Invalid chunk structure
  InvalidChunk
} derive(Debug, Eq)

///|
/// Parse a WAV file from bytes and return the decoded audio data.
///
/// # Arguments
/// * `data` - The raw bytes of the WAV file
///
/// # Returns
/// * `Ok(AudioData)` - Successfully decoded audio data
/// * `Err(WavError)` - Error during decoding
pub fn decode(data : Bytes) -> Result[AudioData, WavError] {
  // Validate RIFF header
  match validate_riff_header(data) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  // Parse chunks
  match parse_chunks(data) {
    Ok((info, audio_bytes)) =>
      // Decode audio samples based on format
      if info.audio_format == 3 {
        // IEEE float format
        match decode_ieee_float(audio_bytes) {
          Ok(samples) => Ok({ samples, info })
          Err(e) => Err(e)
        }
      } else {
        // PCM format
        match decode_pcm_samples(audio_bytes, info.bits_per_sample) {
          Ok(samples) => Ok({ samples, info })
          Err(e) => Err(e)
        }
      }
    Err(e) => Err(e)
  }
}

///|
/// Get WAV file information without decoding the audio data.
///
/// # Arguments
/// * `data` - The raw bytes of the WAV file
///
/// # Returns
/// * `Ok(WavInfo)` - WAV file format information
/// * `Err(WavError)` - Error during parsing
pub fn get_info(data : Bytes) -> Result[WavInfo, WavError] {
  match validate_riff_header(data) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  match parse_chunks(data) {
    Ok((info, _)) => Ok(info)
    Err(e) => Err(e)
  }
}

///|
/// Validate the RIFF header of a WAV file.
fn validate_riff_header(data : Bytes) -> Result[Unit, WavError] {
  // RIFF header: "RIFF" + 4 bytes size + "WAVE"
  match data {
    [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'A', b'V', b'E', ..] => Ok(())
    _ => Err(InvalidHeader)
  }
}

///|
/// Parse RIFF chunks to find fmt and data chunks.
fn parse_chunks(data : Bytes) -> Result[(WavInfo, Bytes), WavError] {
  // Skip RIFF header (12 bytes)
  let view = data[12:]
  let mut pos = 0
  let mut fmt_info : WavInfo? = None
  let mut audio_start : Int? = None
  let mut audio_size : Int = 0

  while pos + 8 <= view.length() {
    // Parse chunk header
    match parse_chunk_header(view, pos) {
      Ok((chunk_id, chunk_size)) => {
        pos = pos + 8

        // Check if we have enough data for this chunk
        if pos + chunk_size > view.length() {
          return Err(CorruptedData)
        }

        // Process chunk based on ID
        if chunk_id == b"fmt " {
          match parse_fmt_chunk(view, pos, chunk_size) {
            Ok(info) => fmt_info = info
            Err(e) => return Err(e)
          }
        } else if chunk_id == b"data" {
          audio_start = Some(pos)
          audio_size = chunk_size
        }

        // Move to next chunk (chunks are 2-byte aligned)
        pos = pos + chunk_size
        if chunk_size % 2 != 0 {
          pos = pos + 1
        }
      }
      Err(e) => return Err(e)
    }
  }

  // Both fmt and data chunks are required
  match (fmt_info, audio_start) {
    (Some(info), Some(start)) => {
      // Create new info with updated data_size
      let updated_info : WavInfo = {
        audio_format: info.audio_format,
        num_channels: info.num_channels,
        sample_rate: info.sample_rate,
        byte_rate: info.byte_rate,
        block_align: info.block_align,
        bits_per_sample: info.bits_per_sample,
        data_size: audio_size,
      }
      // Convert BytesView to Bytes using Buffer
      let buf = Buffer(size_hint=audio_size)
      buf.write_bytesview(view[start:start + audio_size])
      Ok((updated_info, buf.to_bytes()))
    }
    _ => Err(InvalidChunk)
  }
}

///|
/// Parse a chunk header at the given position.
fn parse_chunk_header(
  view : BytesView,
  pos : Int,
) -> Result[(Bytes, Int), WavError] {
  match view[pos:pos + 8] {
    [id0, id1, id2, id3, s0, s1, s2, s3, ..] => {
      // Build chunk ID as Bytes
      let id = Bytes::from_array([id0, id1, id2, id3])

      // Parse size (little-endian 32-bit)
      let size = s0.to_int() |
        (s1.to_int() << 8) |
        (s2.to_int() << 16) |
        (s3.to_int() << 24)

      Ok((id, size))
    }
    _ => Err(CorruptedData)
  }
}

///|
/// Parse the fmt chunk to extract format information.
fn parse_fmt_chunk(
  view : BytesView,
  pos : Int,
  size : Int,
) -> Result[WavInfo?, WavError] {
  // fmt chunk minimum size is 16 bytes
  if size < 16 {
    return Err(InvalidChunk)
  }

  match view[pos:pos + 16] {
    [f0, f1, c0, c1, r0, r1, r2, r3, b0, b1, b2, b3, a0, a1, p0, p1, ..] => {
      // Parse fields (little-endian)
      let audio_format = f0.to_int() | (f1.to_int() << 8)
      let num_channels = c0.to_int() | (c1.to_int() << 8)
      let sample_rate = r0.to_int() |
        (r1.to_int() << 8) |
        (r2.to_int() << 16) |
        (r3.to_int() << 24)
      let byte_rate = b0.to_int() |
        (b1.to_int() << 8) |
        (b2.to_int() << 16) |
        (b3.to_int() << 24)
      let block_align = a0.to_int() | (a1.to_int() << 8)
      let bits_per_sample = p0.to_int() | (p1.to_int() << 8)

      // Support PCM (1) and IEEE float (3) formats
      if audio_format != 1 && audio_format != 3 {
        return Err(UnsupportedFormat)
      }

      Ok(
        Some({
            audio_format,
            num_channels,
            sample_rate,
            byte_rate,
            block_align,
            bits_per_sample,
            data_size: 0,
          }, // Will be updated from data chunk
        ),
      )
    }
    _ => Err(CorruptedData)
  }
}

///|
/// Decode PCM samples from raw audio bytes.
fn decode_pcm_samples(
  data : Bytes,
  bits_per_sample : Int,
) -> Result[Array[Int], WavError] {
  match bits_per_sample {
    8 => decode_pcm_8bit(data)
    16 => decode_pcm_16bit(data)
    24 => decode_pcm_24bit(data)
    32 => decode_pcm_32bit(data)
    _ => Err(UnsupportedFormat)
  }
}

///|
/// Decode 8-bit PCM samples (unsigned, centered at 128).
fn decode_pcm_8bit(data : Bytes) -> Result[Array[Int], WavError] {
  let samples = []
  let view = data[:]
  let mut i = 0

  while i < view.length() {
    // 8-bit PCM is unsigned, convert to signed (-128 to 127)
    let sample = view[i].to_int() - 128
    samples.push(sample)
    i = i + 1
  }

  Ok(samples)
}

///|
/// Decode 16-bit PCM samples (signed, little-endian).
fn decode_pcm_16bit(data : Bytes) -> Result[Array[Int], WavError] {
  let samples = []
  let view = data[:]
  let mut i = 0

  while i + 1 < view.length() {
    // Read 16-bit little-endian signed integer
    let low = view[i].to_int()
    let high = view[i + 1].to_int()
    let sample = low | (high << 8)

    // Sign extend from 16-bit to 32-bit
    let signed_sample = if sample >= 0x8000 { sample - 0x10000 } else { sample }

    samples.push(signed_sample)
    i = i + 2
  }

  Ok(samples)
}

///|
/// Decode 24-bit PCM samples (signed, little-endian).
fn decode_pcm_24bit(data : Bytes) -> Result[Array[Int], WavError] {
  let samples = []
  let view = data[:]
  let mut i = 0

  while i + 2 < view.length() {
    // Read 24-bit little-endian signed integer
    let b0 = view[i].to_int()
    let b1 = view[i + 1].to_int()
    let b2 = view[i + 2].to_int()
    let sample = b0 | (b1 << 8) | (b2 << 16)

    // Sign extend from 24-bit to 32-bit
    let signed_sample = if sample >= 0x800000 {
      sample - 0x1000000
    } else {
      sample
    }

    samples.push(signed_sample)
    i = i + 3
  }

  Ok(samples)
}

///|
/// Decode 32-bit PCM samples (signed, little-endian).
fn decode_pcm_32bit(data : Bytes) -> Result[Array[Int], WavError] {
  let samples = []
  let view = data[:]
  let mut i = 0

  while i + 3 < view.length() {
    // Read 32-bit little-endian signed integer
    let b0 = view[i].to_int()
    let b1 = view[i + 1].to_int()
    let b2 = view[i + 2].to_int()
    let b3 = view[i + 3].to_int()
    let sample = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

    samples.push(sample)
    i = i + 4
  }

  Ok(samples)
}

///|
/// Decode IEEE 754 32-bit float samples and convert to 32-bit integer range.
fn decode_ieee_float(data : Bytes) -> Result[Array[Int], WavError] {
  let samples = []
  let view = data[:]
  let mut i = 0

  while i + 3 < view.length() {
    // Read 4 bytes as little-endian 32-bit integer
    let b0 = view[i].to_int()
    let b1 = view[i + 1].to_int()
    let b2 = view[i + 2].to_int()
    let b3 = view[i + 3].to_int()
    let bits = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

    // Extract IEEE 754 components
    let sign = if (bits & 0x80000000) != 0 { -1.0 } else { 1.0 }
    let exponent = (bits >> 23) & 0xFF
    let mantissa = bits & 0x7FFFFF

    // Convert to double
    let float_val = if exponent == 0 {
      // Denormalized or zero
      sign * Double::from_int(mantissa) * 1.401298464324817e-45
    } else if exponent == 255 {
      // Infinity or NaN - clamp to max/min
      if mantissa == 0 {
        sign * 1.0e30
      } else {
        0.0
      }
    } else {
      // Normalized
      let exp_val = Double::from_int(exponent - 127)
      let mantissa_val = 1.0 + Double::from_int(mantissa) / 8388608.0
      sign * mantissa_val * exp_val.exp2()
    }

    // Scale to 32-bit integer range [-2^31, 2^31-1]
    let scaled = float_val * 2147483648.0
    let clamped = if scaled < -2147483648.0 {
      -2147483648
    } else if scaled > 2147483647.0 {
      2147483647
    } else {
      scaled.to_int()
    }

    samples.push(clamped)
    i = i + 4
  }

  Ok(samples)
}
