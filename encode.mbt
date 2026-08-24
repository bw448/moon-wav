// WAV encoder - write audio data to WAV file format

///|
/// Encode audio samples and format info into a WAV file.
///
/// # Arguments
/// * `audio` - The audio data to encode
///
/// # Returns
/// * `Bytes` - The encoded WAV file bytes
pub fn encode(audio : AudioData) -> Bytes {
  let info = audio.info
  let samples = audio.samples
  let bytes_per_sample = info.bits_per_sample / 8
  let data_size = samples.length() * bytes_per_sample
  let file_size = 36 + data_size

  let buf = Buffer(size_hint=file_size + 12)

  // RIFF header
  buf.write_bytes(b"RIFF")
  buf.write_int_le(file_size)
  buf.write_bytes(b"WAVE")

  // fmt chunk
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16) // chunk size
  buf.write_int16_le(info.audio_format.to_int16())
  buf.write_int16_le(info.num_channels.to_int16())
  buf.write_int_le(info.sample_rate)
  buf.write_int_le(info.byte_rate)
  buf.write_int16_le(info.block_align.to_int16())
  buf.write_int16_le(info.bits_per_sample.to_int16())

  // data chunk
  buf.write_bytes(b"data")
  buf.write_int_le(data_size)

  // Encode samples based on bit depth
  match info.bits_per_sample {
    8 => encode_samples_8bit(buf, samples)
    16 => encode_samples_16bit(buf, samples)
    24 => encode_samples_24bit(buf, samples)
    32 => encode_samples_32bit(buf, samples)
    _ => () // Should not happen with valid WavInfo
  }

  buf.to_bytes()
}

///|
/// Encode audio samples into a WAV file with specified format.
///
/// # Arguments
/// * `samples` - The audio samples
/// * `num_channels` - Number of channels (1 or 2)
/// * `sample_rate` - Sample rate in Hz
/// * `bits_per_sample` - Bit depth (8, 16, 24, or 32)
///
/// # Returns
/// * `Bytes` - The encoded WAV file bytes
pub fn encode_with_format(
  samples : Array[Int],
  num_channels : Int,
  sample_rate : Int,
  bits_per_sample : Int,
) -> Bytes {
  let bytes_per_sample = bits_per_sample / 8
  let byte_rate = sample_rate * num_channels * bytes_per_sample
  let block_align = num_channels * bytes_per_sample

  let info : WavInfo = {
    audio_format: 1,
    num_channels,
    sample_rate,
    byte_rate,
    block_align,
    bits_per_sample,
    data_size: samples.length() * bytes_per_sample,
  }

  encode({ samples, info })
}

///|
/// Encode 8-bit PCM samples (unsigned, centered at 128).
fn encode_samples_8bit(buf : Buffer, samples : Array[Int]) -> Unit {
  let mut i = 0
  while i < samples.length() {
    // Convert signed to unsigned: add 128, clamp to [0, 255]
    let val = samples[i] + 128
    let clamped = if val < 0 { 0 } else if val > 255 { 255 } else { val }
    buf.write_byte(clamped.to_byte())
    i = i + 1
  }
}

///|
/// Encode 16-bit PCM samples (signed, little-endian).
fn encode_samples_16bit(buf : Buffer, samples : Array[Int]) -> Unit {
  let mut i = 0
  while i < samples.length() {
    let clamped = if samples[i] < -32768 {
      -32768
    } else if samples[i] > 32767 {
      32767
    } else {
      samples[i]
    }
    buf.write_int16_le(clamped.to_int16())
    i = i + 1
  }
}

///|
/// Encode 24-bit PCM samples (signed, little-endian).
fn encode_samples_24bit(buf : Buffer, samples : Array[Int]) -> Unit {
  let mut i = 0
  while i < samples.length() {
    let clamped = if samples[i] < -8388608 {
      -8388608
    } else if samples[i] > 8388607 {
      8388607
    } else {
      samples[i]
    }
    buf.write_byte((clamped & 0xFF).to_byte())
    buf.write_byte(((clamped >> 8) & 0xFF).to_byte())
    buf.write_byte(((clamped >> 16) & 0xFF).to_byte())
    i = i + 1
  }
}

///|
/// Encode 32-bit PCM samples (signed, little-endian).
fn encode_samples_32bit(buf : Buffer, samples : Array[Int]) -> Unit {
  let mut i = 0
  while i < samples.length() {
    let s = samples[i]
    buf.write_byte((s & 0xFF).to_byte())
    buf.write_byte(((s >> 8) & 0xFF).to_byte())
    buf.write_byte(((s >> 16) & 0xFF).to_byte())
    buf.write_byte(((s >> 24) & 0xFF).to_byte())
    i = i + 1
  }
}
