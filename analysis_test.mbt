// Tests for audio analysis

///|
test "analyze basic audio" {
  let samples = [100, -100, 200, -200, 300, -300]
  let info = make_wav_info(1, 1, 44100, 88200, 2, 16, 12)
  let audio = make_audio_data(samples, info)
  let result = analyze(audio, 100)

  assert_true(result.peak > 0)
  assert_true(result.rms > 0.0)
  assert_true(result.samples_per_channel == 6)
}

///|
test "calculate_dc_offset balanced" {
  let samples = [100, -100, 200, -200]
  let dc = calculate_dc_offset(samples)

  assert_true(dc.abs() < 1.0)
}

///|
test "calculate_dc_offset positive bias" {
  let samples = [100, 200, 300, 400]
  let dc = calculate_dc_offset(samples)

  assert_true(dc > 200.0)
}

///|
test "calculate_dc_offset empty" {
  let samples : Array[Int] = []
  let dc = calculate_dc_offset(samples)

  assert_true(dc.abs() < 0.01)
}

///|
test "count_zero_crossings" {
  // Signal: +, +, -, -, +, -
  let samples = [100, 200, -100, -200, 100, -100]
  let crossings = count_zero_crossings(samples)

  // Crossings at: index 1->2, 3->4, 4->5 = 3 crossings
  assert_eq(crossings, 3)
}

///|
test "count_zero_crossings all positive" {
  let samples = [100, 200, 300, 400]
  let crossings = count_zero_crossings(samples)

  assert_eq(crossings, 0)
}

///|
test "count_clipped_samples" {
  let samples = [32767, -32768, 100, 0, 32767]
  let clipped = count_clipped_samples(samples, -32768, 32767)

  assert_eq(clipped, 3) // 32767, -32768, 32767
}

///|
test "count_silent_samples" {
  let samples = [10, -5, 2000, -3000, 8, -2]
  let silent = count_silent_samples(samples, 100)

  assert_eq(silent, 4) // 10, -5, 8, -2 are below threshold
}

///|
test "analyze silence detection" {
  let samples = [0, 0, 0, 0, 0, 1000]
  let info = make_wav_info(1, 1, 44100, 88200, 2, 16, 12)
  let audio = make_audio_data(samples, info)
  let result = analyze(audio, 100)

  assert_true(!result.is_silent) // Not 95% silent
  assert_true(result.silence_ratio > 0.5)
}
