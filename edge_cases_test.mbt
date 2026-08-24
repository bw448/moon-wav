// Edge case tests for WAV library

///|
test "decode empty data chunk" {
  let buf = Buffer(size_hint=100)
  buf.write_bytes(b"RIFF")
  buf.write_int_le(36)
  buf.write_bytes(b"WAVE")
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16)
  buf.write_int16_le(1) // PCM
  buf.write_int16_le(1) // mono
  buf.write_int_le(44100)
  buf.write_int_le(88200)
  buf.write_int16_le(2)
  buf.write_int16_le(16)
  buf.write_bytes(b"data")
  buf.write_int_le(0)

  let result = decode(buf.to_bytes())

  match result {
    Ok(audio) => {
      assert_eq(audio.samples.length(), 0)
      assert_eq(audio.info.bits_per_sample, 16)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode 24-bit stereo" {
  let samples = [100000, -100000, 200000, -200000]
  let wav_data = create_test_wav(2, 48000, 24, samples)

  let result = decode(wav_data)

  match result {
    Ok(audio) => {
      assert_eq(audio.info.num_channels, 2)
      assert_eq(audio.info.sample_rate, 48000)
      assert_eq(audio.info.bits_per_sample, 24)
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
test "get_info does not decode samples" {
  let samples = [100, -100, 200, -200]
  let wav_data = create_test_wav(1, 44100, 16, samples)

  let result = get_info(wav_data)

  match result {
    Ok(info) => {
      assert_eq(info.num_channels, 1)
      assert_eq(info.sample_rate, 44100)
      assert_eq(info.bits_per_sample, 16)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "encode decode 32-bit roundtrip" {
  let samples = [1000000, -1000000, 2000000, -2000000]
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate: 44100,
    byte_rate: 176400,
    block_align: 4,
    bits_per_sample: 32,
    data_size: 16,
  }

  let encoded = encode({ samples, info })
  let decoded = decode(encoded)

  match decoded {
    Ok(audio) => {
      assert_eq(audio.info.bits_per_sample, 32)
      assert_eq(audio.samples.length(), 4)
      assert_eq(audio.samples[0], 1000000)
      assert_eq(audio.samples[1], -1000000)
      assert_eq(audio.samples[2], 2000000)
      assert_eq(audio.samples[3], -2000000)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "resample stereo" {
  let samples = [100, 200, 300, 400, 500, 600, 700, 800]
  let result = resample(samples, 44100, 22050, 2)

  // Should have approximately half the samples
  assert_true(result.length() >= 3 && result.length() <= 5)
}

///|
test "convert_bit_depth 24 to 16" {
  let samples = [8388607, -8388608, 0, 4194304]
  let result = convert_bit_depth(samples, 24, 16)

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 4)
      // 8388607 -> ~32767, -8388608 -> ~-32768, 0 -> 0, 4194304 -> ~16384
      assert_true(converted[0] > 32000)
      assert_true(converted[1] < -32000)
      assert_true(converted[2].abs() < 10)
      assert_true(converted[3] > 16000 && converted[3] < 17000)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "trim empty range" {
  let samples = [10, 20, 30]
  let trimmed = trim(samples, 2, 2)

  assert_eq(trimmed.length(), 0)
}

///|
test "concat multiple arrays" {
  let a = [1, 2]
  let b = [3, 4]
  let c = [5, 6]
  let ab = concat(a, b)
  let abc = concat(ab, c)

  assert_eq(abc.length(), 6)
  assert_eq(abc[0], 1)
  assert_eq(abc[5], 6)
}

///|
test "fade_in full length" {
  let samples = [1000, 1000, 1000]
  let result = fade_in(samples, 3)

  assert_eq(result.length(), 3)
  assert_eq(result[0], 0) // factor = 0/3
  assert_true(result[1] > 0 && result[1] < 1000)
  assert_eq(result[2], 1000) // factor = 2/3, but last sample
}

///|
test "fade_out full length" {
  let samples = [1000, 1000, 1000]
  let result = fade_out(samples, 3)

  assert_eq(result.length(), 3)
  assert_eq(result[0], 1000) // first sample
  assert_true(result[1] > 0 && result[1] < 1000)
  assert_eq(result[2], 0) // factor = 0/3
}

///|
test "mix empty with non-empty" {
  let a : Array[Int] = []
  let b = [100, 200, 300]
  let result = mix(a, b)

  assert_eq(result.length(), 3)
  assert_eq(result[0], 50) // (0 + 100) / 2
  assert_eq(result[1], 100) // (0 + 200) / 2
  assert_eq(result[2], 150) // (0 + 300) / 2
}

///|
test "reverse empty" {
  let samples : Array[Int] = []
  let result = reverse(samples)

  assert_eq(result.length(), 0)
}

///|
test "get_rms_level constant" {
  let samples = [1000, 1000, 1000, 1000]
  let rms = get_rms_level(samples)

  // RMS of constant signal = absolute value of the constant
  assert_true((rms - 1000.0).abs() < 0.01)
}

///|
test "validate truncated file" {
  // Create a valid WAV then truncate it
  let samples = [100, -100, 200, -200]
  let wav_data = create_test_wav(1, 44100, 16, samples)

  // Take only first 20 bytes (truncated)
  let truncated = wav_data[:20]
  let result = validate(truncated)

  // Should detect truncation
  assert_true(!result.is_valid || result.warnings.length() > 0)
}

///|
test "analyze clipping detection" {
  let samples = [32767, 32767, 32767, 100, -32768, -32768]
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate: 44100,
    byte_rate: 88200,
    block_align: 2,
    bits_per_sample: 16,
    data_size: 12,
  }
  let audio : AudioData = { samples, info }
  let result = analyze(audio, 100)

  assert_true(result.has_clipping)
  assert_true(result.clipped_samples > 0)
}

///|
test "generate_sine frequency accuracy" {
  // Generate 1 second of 440Hz at 44100Hz sample rate
  let samples = generate_sine(440.0, 16000.0, 44100, 1.0)

  // Count zero crossings
  let crossings = count_zero_crossings(samples)

  // 440Hz should have ~880 zero crossings per second (2 per cycle)
  assert_true(crossings > 800 && crossings < 960)
}

///|
test "normalize preserves relative levels" {
  let samples = [100, 200, 300, 400]
  let result = normalize(samples, 32000)

  // Ratios should be preserved
  // 200/100 = 2.0, result[1]/result[0] should also be ~2.0
  if result[0] != 0 {
    let ratio = Double::from_int(result[1]) / Double::from_int(result[0])
    assert_true((ratio - 2.0).abs() < 0.1)
  }
}

///|
test "echo cascading" {
  let samples = [1000, 0, 0, 0, 0, 0, 0, 0]
  let result = echo(samples, 2, 0.5)

  // 1000 at index 0 -> echo at 2 (500) -> echo at 4 (250) -> echo at 6 (125)
  assert_eq(result[0], 1000)
  assert_eq(result[2], 500)
  assert_eq(result[4], 250)
  assert_eq(result[6], 125)
}

///|
test "low_pass_filter preserves DC" {
  let samples = [1000, 1000, 1000, 1000, 1000]
  let result = low_pass_filter(samples, 3)

  // DC signal should pass through unchanged
  let mut i = 1
  while i < result.length() - 1 {
    assert_true((result[i] - 1000).abs() < 10)
    i = i + 1
  }
}
