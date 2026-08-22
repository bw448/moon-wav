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
  buf.write_int16_le(num_channels.to_int16())
  buf.write_int_le(sample_rate)
  let byte_rate = sample_rate * num_channels * (bits_per_sample / 8)
  buf.write_int_le(byte_rate)
  let block_align = num_channels * (bits_per_sample / 8)
  buf.write_int16_le(block_align.to_int16())
  buf.write_int16_le(bits_per_sample.to_int16())

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
        buf.write_int16_le(clamped.to_int16())
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
  buf.write_int16_le(3) // IEEE float format
  buf.write_int16_le(1)
  buf.write_int_le(44100)
  buf.write_int_le(88200)
  buf.write_int16_le(2)
  buf.write_int16_le(16)
  buf.write_bytes(b"data")
  buf.write_int_le(0)

  let result = decode(buf.to_bytes())
  assert_true(result is Err(UnsupportedFormat))
}
