// Tests for format conversion functions

///|
test "convert_bit_depth 16 to 8" {
  let samples = [0, 32767, -32768, 16384]
  let result = convert_bit_depth(samples, 16, 8)

  assert_true(result is Ok(_))

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 4)
      // 0 -> 0.0 -> 128, 32767 -> ~1.0 -> 255, -32768 -> -1.0 -> 0, 16384 -> 0.5 -> 192
      assert_eq(converted[0], 128)
      assert_true(converted[1] >= 254)
      assert_true(converted[2] <= 1)
      assert_true(converted[3] >= 190 && converted[3] <= 194)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "convert_bit_depth 8 to 16" {
  let samples = [128, 255, 0, 192]
  let result = convert_bit_depth(samples, 8, 16)

  assert_true(result is Ok(_))

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 4)
      // 128 (center) -> ~0, 255 (max) -> ~32767, 0 (min) -> ~-32768, 192 -> ~16384
      assert_true(converted[0].abs() < 100)
      assert_true(converted[1] > 32000)
      assert_true(converted[2] < -32000)
      assert_true(converted[3] > 16000 && converted[3] < 17000)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "convert_bit_depth same depth returns original" {
  let samples = [100, -100, 200, -200]
  let result = convert_bit_depth(samples, 16, 16)

  assert_true(result is Ok(_))

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 4)
      assert_eq(converted[0], 100)
      assert_eq(converted[1], -100)
      assert_eq(converted[2], 200)
      assert_eq(converted[3], -200)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "convert_channels mono to stereo" {
  let samples = [100, 200, 300]
  let result = convert_channels(samples, 1, 2)

  assert_true(result is Ok(_))

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 6)
      assert_eq(converted[0], 100)
      assert_eq(converted[1], 100)
      assert_eq(converted[2], 200)
      assert_eq(converted[3], 200)
      assert_eq(converted[4], 300)
      assert_eq(converted[5], 300)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "convert_channels stereo to mono" {
  let samples = [100, 200, 300, 400]
  let result = convert_channels(samples, 2, 1)

  assert_true(result is Ok(_))

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 2)
      assert_eq(converted[0], 150) // (100 + 200) / 2
      assert_eq(converted[1], 350) // (300 + 400) / 2
    }
    Err(_) => assert_true(false)
  }
}

///|
test "convert_channels same channels returns original" {
  let samples = [100, 200, 300, 400]
  let result = convert_channels(samples, 2, 2)

  assert_true(result is Ok(_))

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 4)
      assert_eq(converted[0], 100)
      assert_eq(converted[1], 200)
      assert_eq(converted[2], 300)
      assert_eq(converted[3], 400)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "resample same rate returns original" {
  let samples = [100, 200, 300, 400]
  let result = resample(samples, 44100, 44100, 1)

  assert_eq(result.length(), 4)
  assert_eq(result[0], 100)
  assert_eq(result[1], 200)
  assert_eq(result[2], 300)
  assert_eq(result[3], 400)
}

///|
test "resample downsample 2x" {
  let samples = [0, 100, 200, 300, 400, 500]
  let result = resample(samples, 44100, 22050, 1)

  // Downsample by 2x: should have ~3 samples
  assert_true(result.length() >= 2 && result.length() <= 4)
}

///|
test "resample upsample 2x" {
  let samples = [0, 100, 200, 300]
  let result = resample(samples, 22050, 44100, 1)

  // Upsample by 2x: should have ~8 samples
  assert_true(result.length() >= 6 && result.length() <= 10)
}

///|
test "convert_bit_depth 16 to 24" {
  let samples = [32767, -32768, 0, 16384]
  let result = convert_bit_depth(samples, 16, 24)

  assert_true(result is Ok(_))

  match result {
    Ok(converted) => {
      assert_eq(converted.length(), 4)
      // 32767 -> ~8388607, -32768 -> ~-8388608, 0 -> 0, 16384 -> ~4194304
      assert_true(converted[0] > 8388000)
      assert_true(converted[1] < -8388000)
      assert_true(converted[2].abs() < 10)
      assert_true(converted[3] > 4194000 && converted[3] < 4195000)
    }
    Err(_) => assert_true(false)
  }
}
