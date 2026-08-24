// Tests for audio generators

///|
test "generate_sine basic" {
  let samples = generate_sine(440.0, 16000.0, 44100, 0.1)

  // 44100 * 0.1 = 4410 samples
  assert_eq(samples.length(), 4410)
  // All samples should be approximately within amplitude range
  let peak = get_peak_amplitude(samples)
  assert_true(peak <= 17000) // Allow some Taylor series overshoot
}

///|
test "generate_square basic" {
  let samples = generate_square(440.0, 16000.0, 44100, 0.1)

  assert_eq(samples.length(), 4410)
  // Square wave should have constant amplitude
  let peak = get_peak_amplitude(samples)
  assert_true(peak > 15000)
}

///|
test "generate_sawtooth basic" {
  let samples = generate_sawtooth(440.0, 16000.0, 44100, 0.1)

  assert_eq(samples.length(), 4410)
  let peak = get_peak_amplitude(samples)
  assert_true(peak > 15000)
}

///|
test "generate_triangle basic" {
  let samples = generate_triangle(440.0, 16000.0, 44100, 0.1)

  assert_eq(samples.length(), 4410)
  let peak = get_peak_amplitude(samples)
  assert_true(peak > 15000)
}

///|
test "generate_noise basic" {
  let samples = generate_noise(16000.0, 44100, 0.1, 42)

  assert_eq(samples.length(), 4410)
  // Noise should have non-zero peak
  let peak = get_peak_amplitude(samples)
  assert_true(peak > 0)
}

///|
test "generate_noise reproducible" {
  let samples1 = generate_noise(16000.0, 44100, 0.1, 42)
  let samples2 = generate_noise(16000.0, 44100, 0.1, 42)

  assert_eq(samples1.length(), samples2.length())
  // Same seed should produce same output
  assert_eq(samples1[0], samples2[0])
  assert_eq(samples1[100], samples2[100])
}

///|
test "generate_chirp basic" {
  let samples = generate_chirp(200.0, 2000.0, 16000.0, 44100, 0.1)

  assert_eq(samples.length(), 4410)
  let peak = get_peak_amplitude(samples)
  assert_true(peak > 0)
}

///|
test "generate_silence basic" {
  let samples = generate_silence(44100, 0.1)

  assert_eq(samples.length(), 4410)
  let peak = get_peak_amplitude(samples)
  assert_eq(peak, 0)
}

///|
test "generate_sine_wav creates valid audio" {
  let audio = generate_sine_wav(440.0, 16000.0, 44100, 0.1, 16)

  assert_eq(audio.info.num_channels, 1)
  assert_eq(audio.info.sample_rate, 44100)
  assert_eq(audio.info.bits_per_sample, 16)
  assert_eq(audio.samples.length(), 4410)
}

///|
test "generate_sine_wav encodes and decodes" {
  let audio = generate_sine_wav(440.0, 16000.0, 44100, 0.1, 16)
  let encoded = encode(audio)
  let decoded = decode(encoded)

  assert_true(decoded is Ok(_))

  match decoded {
    Ok(d) => {
      assert_eq(d.info.sample_rate, 44100)
      assert_eq(d.samples.length(), 4410)
    }
    Err(_) => assert_true(false)
  }
}
