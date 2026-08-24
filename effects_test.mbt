// Tests for audio effects

///|
test "echo basic" {
  let samples = [1000, 0, 0, 0, 0]
  let result = echo(samples, 2, 0.5)

  assert_eq(result.length(), 5)
  assert_eq(result[0], 1000)
  assert_eq(result[1], 0)
  assert_eq(result[2], 500) // echo of 1000 * 0.5
  assert_eq(result[3], 0)
  assert_eq(result[4], 0)
}

///|
test "delay basic" {
  let samples = [1000, 0, 0, 0, 0]
  let result = delay(samples, 2, 0.5)

  assert_eq(result.length(), 5)
  assert_eq(result[0], 500) // 1000 * 0.5 (dry) + 0 * 0.5 (wet)
  assert_eq(result[1], 0)
  assert_eq(result[2], 500) // 0 * 0.5 + 1000 * 0.5
}

///|
test "normalize" {
  let samples = [100, -200, 300, -400]
  let result = normalize(samples, 32000)

  let peak = get_peak_amplitude(result)
  // Peak should be close to 32000
  assert_true(peak >= 31999 && peak <= 32001)
}

///|
test "normalize silent" {
  let samples = [0, 0, 0]
  let result = normalize(samples, 32000)

  // Should return original (all zeros)
  assert_eq(result[0], 0)
  assert_eq(result[1], 0)
  assert_eq(result[2], 0)
}

///|
test "soft_clip" {
  let samples = [40000, -40000, 10000, -10000]
  let result = soft_clip(samples, 30000)

  assert_eq(result.length(), 4)
  // Values above threshold should be reduced
  assert_true(result[0].abs() < 40000)
  assert_true(result[1].abs() < 40000)
  // Values below threshold should be mostly unchanged
  assert_true(result[2].abs() >= 9000)
  assert_true(result[3].abs() >= 9000)
}

///|
test "remove_dc_offset" {
  let samples = [1100, 1200, 1150, 1250] // DC offset ~1175
  let result = remove_dc_offset(samples)

  let dc = calculate_dc_offset(result)
  // DC offset should be close to zero
  assert_true(dc.abs() < 2.0)
}

///|
test "low_pass_filter" {
  let samples = [1000, -1000, 1000, -1000, 1000]
  let result = low_pass_filter(samples, 3)

  assert_eq(result.length(), 5)
  // High-frequency content should be reduced
  let original_peak = get_peak_amplitude(samples)
  let filtered_peak = get_peak_amplitude(result)
  assert_true(filtered_peak <= original_peak)
}

///|
test "high_pass_filter" {
  let samples = [1000, 1000, 1000, 1000, 1000] // DC signal
  let result = high_pass_filter(samples, 3)

  assert_eq(result.length(), 5)
  // DC component should be removed
  let peak = get_peak_amplitude(result)
  assert_true(peak < 1000)
}

///|
test "reverse_reverb" {
  let samples = [0, 1000, 2000, 3000, 4000]
  let result = reverse_reverb(samples, 2)

  assert_eq(result.length(), 5)
  // First sample should be faded in (close to 0)
  assert_true(result[0].abs() < 100)
}
