// Tests for WAV decoding library

///|
/// Create a minimal valid WAV file for testing.
fn create_test_wav(
  num_channels : Int,
  sample_rate : Int,
  bits_per_sample : Int,
  samples : Array[Int],
) -> Bytes {
  let buf = Buffer(size_hint=1024)

  // RIFF header
  buf.write_bytes(b"RIFF")
  let data_size = samples.length() * (bits_per_sample / 8)
  let file_size = 36 + data_size
  buf.write_int_le(file_size)
  buf.write_bytes(b"WAVE")

  // fmt chunk
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16) // chunk size
  buf.write_int16_le(1) // PCM format
  buf.write_int16_le(Int16::from_int(num_channels))
  buf.write_int_le(sample_rate)
  let byte_rate = sample_rate * num_channels * (bits_per_sample / 8)
  buf.write_int_le(byte_rate)
  let block_align = num_channels * (bits_per_sample / 8)
  buf.write_int16_le(Int16::from_int(block_align))
  buf.write_int16_le(Int16::from_int(bits_per_sample))

  // data chunk
  buf.write_bytes(b"data")
  buf.write_int_le(data_size)

  // Write samples
  let mut i = 0
  while i < samples.length() {
    let sample = samples[i]
    match bits_per_sample {
      8 => buf.write_byte((sample + 128).to_byte())
      16 => {
        let clamped = if sample < -32768 {
          -32768
        } else if sample > 32767 {
          32767
        } else {
          sample
        }
        buf.write_int16_le(Int16::from_int(clamped))
      }
      24 => {
        let clamped = if sample < -8388608 {
          -8388608
        } else if sample > 8388607 {
          8388607
        } else {
          sample
        }
        buf.write_byte((clamped & 0xFF).to_byte())
        buf.write_byte(((clamped >> 8) & 0xFF).to_byte())
        buf.write_byte(((clamped >> 16) & 0xFF).to_byte())
      }
      32 => {
        buf.write_byte((sample & 0xFF).to_byte())
        buf.write_byte(((sample >> 8) & 0xFF).to_byte())
        buf.write_byte(((sample >> 16) & 0xFF).to_byte())
        buf.write_byte(((sample >> 24) & 0xFF).to_byte())
      }
      _ => ()
    }
    i = i + 1
  }

  buf.to_bytes()
}

///|
test "decode 16-bit mono WAV" {
  let samples = [100, -100, 200, -200]
  let wav_data = create_test_wav(1, 44100, 16, samples)

  let result = decode(wav_data)
  assert_true(result is Ok(_))

  match result {
    Ok(audio) => {
      assert_eq(audio.info.num_channels, 1)
      assert_eq(audio.info.sample_rate, 44100)
      assert_eq(audio.info.bits_per_sample, 16)
      assert_eq(audio.samples.length(), 4)
      assert_eq(audio.samples[0], 100)
      assert_eq(audio.samples[1], -100)
      assert_eq(audio.samples[2], 200)
      assert_eq(audio.samples[3], -200)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode 8-bit mono WAV" {
  // 8-bit PCM is unsigned: 0 = -128, 128 = 0, 255 = 127
  // We create samples as signed values, then encode them
  let samples = [0, 127, -128, 50]
  let wav_data = create_test_wav(1, 22050, 8, samples)

  let result = decode(wav_data)
  assert_true(result is Ok(_))

  match result {
    Ok(audio) => {
      assert_eq(audio.info.num_channels, 1)
      assert_eq(audio.info.sample_rate, 22050)
      assert_eq(audio.info.bits_per_sample, 8)
      assert_eq(audio.samples.length(), 4)
      // 8-bit: encode (sample + 128), decode (byte - 128)
      // 0 -> 128 -> 0, 127 -> 255 -> 127, -128 -> 0 -> -128, 50 -> 178 -> 50
      assert_eq(audio.samples[0], 0)
      assert_eq(audio.samples[1], 127)
      assert_eq(audio.samples[2], -128)
      assert_eq(audio.samples[3], 50)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode 16-bit stereo WAV" {
  let samples = [100, 200, -100, -200]
  let wav_data = create_test_wav(2, 44100, 16, samples)

  let result = decode(wav_data)
  assert_true(result is Ok(_))

  match result {
    Ok(audio) => {
      assert_eq(audio.info.num_channels, 2)
      assert_eq(audio.info.sample_rate, 44100)
      assert_eq(audio.info.bits_per_sample, 16)
      assert_eq(audio.samples.length(), 4)
      assert_eq(audio.samples[0], 100)
      assert_eq(audio.samples[1], 200)
      assert_eq(audio.samples[2], -100)
      assert_eq(audio.samples[3], -200)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "get_info returns format info" {
  let samples = [0, 0, 0, 0]
  let wav_data = create_test_wav(1, 48000, 16, samples)

  let result = get_info(wav_data)
  assert_true(result is Ok(_))

  match result {
    Ok(info) => {
      assert_eq(info.num_channels, 1)
      assert_eq(info.sample_rate, 48000)
      assert_eq(info.bits_per_sample, 16)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "invalid header returns error" {
  let invalid_data = Bytes::from_array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  let result = decode(invalid_data)
  assert_true(result is Err(InvalidHeader))
}

///|
test "non-PCM format returns error" {
  let buf = Buffer(size_hint=100)
  buf.write_bytes(b"RIFF")
  buf.write_int_le(36)
  buf.write_bytes(b"WAVE")
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16)
  buf.write_int16_le(Int16::from_int(2)) // ADPCM format (unsupported)
  buf.write_int16_le(Int16::from_int(1))
  buf.write_int_le(44100)
  buf.write_int_le(88200)
  buf.write_int16_le(Int16::from_int(2))
  buf.write_int16_le(Int16::from_int(16))
  buf.write_bytes(b"data")
  buf.write_int_le(0)

  let result = decode(buf.to_bytes())
  assert_true(result is Err(UnsupportedFormat))
}

///|
test "decode 32-bit mono WAV" {
  let samples = [100000, -100000, 200000, -200000]
  let wav_data = create_test_wav(1, 44100, 32, samples)

  let result = decode(wav_data)
  assert_true(result is Ok(_))

  match result {
    Ok(audio) => {
      assert_eq(audio.info.num_channels, 1)
      assert_eq(audio.info.sample_rate, 44100)
      assert_eq(audio.info.bits_per_sample, 32)
      assert_eq(audio.samples.length(), 4)
      assert_eq(audio.samples[0], 100000)
      assert_eq(audio.samples[1], -100000)
      assert_eq(audio.samples[2], 200000)
      assert_eq(audio.samples[3], -200000)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode IEEE float mono WAV" {
  // Create a WAV with IEEE float format (audio_format=3)
  let buf = Buffer(size_hint=1024)
  let num_samples = 4
  let sample_rate = 44100
  let bits_per_sample = 32

  // RIFF header
  buf.write_bytes(b"RIFF")
  let data_size = num_samples * 4
  let file_size = 36 + data_size
  buf.write_int_le(file_size)
  buf.write_bytes(b"WAVE")

  // fmt chunk
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16)
  buf.write_int16_le(3) // IEEE float format
  buf.write_int16_le(1) // mono
  buf.write_int_le(sample_rate)
  let byte_rate = sample_rate * 1 * 4
  buf.write_int_le(byte_rate)
  buf.write_int16_le(Int16::from_int(4)) // block align
  buf.write_int16_le(Int16::from_int(bits_per_sample))

  // data chunk
  buf.write_bytes(b"data")
  buf.write_int_le(data_size)

  // Write float samples: 0.5, -0.5, 1.0, -1.0
  // IEEE 754: 0.5 = 0x3F000000, -0.5 = 0xBF000000
  //           1.0 = 0x3F800000, -1.0 = 0xBF800000
  let float_samples = [0x3F000000, 0xBF000000, 0x3F800000, 0xBF800000]
  let mut i = 0
  while i < 4 {
    let s = float_samples[i]
    buf.write_byte((s & 0xFF).to_byte())
    buf.write_byte(((s >> 8) & 0xFF).to_byte())
    buf.write_byte(((s >> 16) & 0xFF).to_byte())
    buf.write_byte(((s >> 24) & 0xFF).to_byte())
    i = i + 1
  }

  let result = decode(buf.to_bytes())
  assert_true(result is Ok(_))

  match result {
    Ok(audio) => {
      assert_eq(audio.info.audio_format, 3)
      assert_eq(audio.info.num_channels, 1)
      assert_eq(audio.info.sample_rate, 44100)
      assert_eq(audio.samples.length(), 4)
      // 0.5 * 2^31 = 1073741824
      assert_true((audio.samples[0] - 1073741824).abs() < 1000)
      // -0.5 * 2^31 = -1073741824
      assert_true((audio.samples[1] + 1073741824).abs() < 1000)
      // 1.0 * 2^31 = 2147483648, clamped to 2147483647
      assert_true(audio.samples[2] > 2000000000)
      // -1.0 * 2^31 = -2147483648
      assert_true(audio.samples[3] < -2000000000)
    }
    Err(_) => assert_true(false)
  }
}
