// Tests for audio operations

///|
test "trim samples" {
  let samples = [10, 20, 30, 40, 50]
  let trimmed = trim(samples, 1, 4)

  assert_eq(trimmed.length(), 3)
  assert_eq(trimmed[0], 20)
  assert_eq(trimmed[1], 30)
  assert_eq(trimmed[2], 40)
}

///|
test "trim clamps to bounds" {
  let samples = [10, 20, 30]
  let trimmed = trim(samples, -1, 100)

  assert_eq(trimmed.length(), 3)
  assert_eq(trimmed[0], 10)
  assert_eq(trimmed[1], 20)
  assert_eq(trimmed[2], 30)
}

///|
test "concat samples" {
  let a = [10, 20]
  let b = [30, 40, 50]
  let result = concat(a, b)

  assert_eq(result.length(), 5)
  assert_eq(result[0], 10)
  assert_eq(result[1], 20)
  assert_eq(result[2], 30)
  assert_eq(result[3], 40)
  assert_eq(result[4], 50)
}

///|
test "concat empty arrays" {
  let a : Array[Int] = []
  let b = [10, 20]
  let result = concat(a, b)

  assert_eq(result.length(), 2)
  assert_eq(result[0], 10)
  assert_eq(result[1], 20)
}

///|
test "adjust_volume half" {
  let samples = [1000, -1000, 2000, -2000]
  let result = adjust_volume(samples, 0.5)

  assert_eq(result.length(), 4)
  assert_eq(result[0], 500)
  assert_eq(result[1], -500)
  assert_eq(result[2], 1000)
  assert_eq(result[3], -1000)
}

///|
test "adjust_volume double" {
  let samples = [1000, -1000]
  let result = adjust_volume(samples, 2.0)

  assert_eq(result.length(), 2)
  assert_eq(result[0], 2000)
  assert_eq(result[1], -2000)
}

///|
test "adjust_volume zero" {
  let samples = [1000, -1000, 2000]
  let result = adjust_volume(samples, 0.0)

  assert_eq(result.length(), 3)
  assert_eq(result[0], 0)
  assert_eq(result[1], 0)
  assert_eq(result[2], 0)
}

///|
test "mix same length" {
  let a = [100, 200, 300]
  let b = [400, 500, 600]
  let result = mix(a, b)

  assert_eq(result.length(), 3)
  assert_eq(result[0], 250) // (100 + 400) / 2
  assert_eq(result[1], 350) // (200 + 500) / 2
  assert_eq(result[2], 450) // (300 + 600) / 2
}

///|
test "mix different length" {
  let a = [100, 200]
  let b = [400, 500, 600, 700]
  let result = mix(a, b)

  assert_eq(result.length(), 4)
  assert_eq(result[0], 250) // (100 + 400) / 2
  assert_eq(result[1], 350) // (200 + 500) / 2
  assert_eq(result[2], 300) // (0 + 600) / 2
  assert_eq(result[3], 350) // (0 + 700) / 2
}

///|
test "fade_in" {
  let samples = [1000, 1000, 1000, 1000]
  let result = fade_in(samples, 2)

  assert_eq(result.length(), 4)
  assert_eq(result[0], 0) // factor = 0/2 = 0.0
  assert_eq(result[1], 500) // factor = 1/2 = 0.5
  assert_eq(result[2], 1000) // beyond fade range
  assert_eq(result[3], 1000) // beyond fade range
}

///|
test "fade_out" {
  let samples = [1000, 1000, 1000, 1000]
  let result = fade_out(samples, 2)

  assert_eq(result.length(), 4)
  assert_eq(result[0], 1000) // before fade range
  assert_eq(result[1], 1000) // before fade range
  assert_eq(result[2], 500) // factor = 1/2 = 0.5
  assert_eq(result[3], 0) // factor = 0/2 = 0.0
}

///|
test "reverse" {
  let samples = [10, 20, 30, 40, 50]
  let result = reverse(samples)

  assert_eq(result.length(), 5)
  assert_eq(result[0], 50)
  assert_eq(result[1], 40)
  assert_eq(result[2], 30)
  assert_eq(result[3], 20)
  assert_eq(result[4], 10)
}

///|
test "reverse single element" {
  let samples = [42]
  let result = reverse(samples)

  assert_eq(result.length(), 1)
  assert_eq(result[0], 42)
}

///|
test "get_peak_amplitude" {
  let samples = [100, -500, 300, -200]
  let peak = get_peak_amplitude(samples)

  assert_eq(peak, 500)
}

///|
test "get_peak_amplitude all positive" {
  let samples = [100, 200, 300]
  let peak = get_peak_amplitude(samples)

  assert_eq(peak, 300)
}

///|
test "get_peak_amplitude empty" {
  let samples : Array[Int] = []
  let peak = get_peak_amplitude(samples)

  assert_eq(peak, 0)
}

///|
test "get_rms_level" {
  let samples = [100, -100, 100, -100]
  let rms = get_rms_level(samples)

  // RMS of [100, -100, 100, -100] = sqrt((10000+10000+10000+10000)/4) = sqrt(10000) = 100
  assert_true((rms - 100.0).abs() < 0.01)
}

///|
test "get_rms_level empty" {
  let samples : Array[Int] = []
  let rms = get_rms_level(samples)

  assert_true(rms.abs() < 0.01)
}
