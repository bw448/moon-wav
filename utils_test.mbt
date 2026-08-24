// Tests for utility functions

///|
test "format_wav_info" {
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 2,
    sample_rate: 44100,
    byte_rate: 176400,
    block_align: 4,
    bits_per_sample: 16,
    data_size: 176400,
  }
  let formatted = format_wav_info(info)

  // Should contain key information
  assert_true(formatted.contains("PCM"))
  assert_true(formatted.contains("Stereo"))
  assert_true(formatted.contains("44100"))
}

///|
test "split_stereo" {
  let samples = [100, 200, 300, 400, 500, 600]
  let (left, right) = split_stereo(samples)

  assert_eq(left.length(), 3)
  assert_eq(right.length(), 3)
  assert_eq(left[0], 100)
  assert_eq(left[1], 300)
  assert_eq(left[2], 500)
  assert_eq(right[0], 200)
  assert_eq(right[1], 400)
  assert_eq(right[2], 600)
}

///|
test "combine_stereo" {
  let left = [100, 300, 500]
  let right = [200, 400, 600]
  let result = combine_stereo(left, right)

  assert_eq(result.length(), 6)
  assert_eq(result[0], 100)
  assert_eq(result[1], 200)
  assert_eq(result[2], 300)
  assert_eq(result[3], 400)
  assert_eq(result[4], 500)
  assert_eq(result[5], 600)
}

///|
test "split and combine roundtrip" {
  let original = [10, 20, 30, 40, 50, 60]
  let (left, right) = split_stereo(original)
  let combined = combine_stereo(left, right)

  assert_eq(combined.length(), original.length())
  let mut i = 0
  while i < original.length() {
    assert_eq(combined[i], original[i])
    i = i + 1
  }
}

///|
test "get_duration" {
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate: 44100,
    byte_rate: 88200,
    block_align: 2,
    bits_per_sample: 16,
    data_size: 88200,
  }
  let audio : AudioData = { samples: [], info }
  let duration = get_duration(audio)

  // 88200 / 88200 = 1.0 second
  assert_true((duration - 1.0).abs() < 0.01)
}

///|
test "get_frame_count mono" {
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate: 44100,
    byte_rate: 88200,
    block_align: 2,
    bits_per_sample: 16,
    data_size: 8,
  }
  let audio : AudioData = { samples: [100, 200, 300, 400], info }
  let frames = get_frame_count(audio)

  assert_eq(frames, 4)
}

///|
test "get_frame_count stereo" {
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 2,
    sample_rate: 44100,
    byte_rate: 176400,
    block_align: 4,
    bits_per_sample: 16,
    data_size: 8,
  }
  let audio : AudioData = { samples: [100, 200, 300, 400], info }
  let frames = get_frame_count(audio)

  assert_eq(frames, 2) // 4 samples / 2 channels = 2 frames
}

///|
test "extract_channel left" {
  let samples = [100, 200, 300, 400, 500, 600]
  let left = extract_channel(samples, 2, 0)

  assert_eq(left.length(), 3)
  assert_eq(left[0], 100)
  assert_eq(left[1], 300)
  assert_eq(left[2], 500)
}

///|
test "extract_channel right" {
  let samples = [100, 200, 300, 400, 500, 600]
  let right = extract_channel(samples, 2, 1)

  assert_eq(right.length(), 3)
  assert_eq(right[0], 200)
  assert_eq(right[1], 400)
  assert_eq(right[2], 600)
}

///|
test "mix_multiple" {
  let a = [100, 200, 300]
  let b = [400, 500, 600]
  let c = [700, 800, 900]
  let streams = [a, b, c]
  let result = mix_multiple(streams)

  assert_eq(result.length(), 3)
  assert_eq(result[0], 400) // (100+400+700)/3
  assert_eq(result[1], 500) // (200+500+800)/3
  assert_eq(result[2], 600) // (300+600+900)/3
}

///|
test "repeat" {
  let samples = [10, 20, 30]
  let result = repeat(samples, 3)

  assert_eq(result.length(), 9)
  assert_eq(result[0], 10)
  assert_eq(result[3], 10)
  assert_eq(result[6], 10)
  assert_eq(result[1], 20)
  assert_eq(result[4], 20)
}

///|
test "pad_to_length" {
  let samples = [10, 20, 30]
  let result = pad_to_length(samples, 5)

  assert_eq(result.length(), 5)
  assert_eq(result[0], 10)
  assert_eq(result[1], 20)
  assert_eq(result[2], 30)
  assert_eq(result[3], 0)
  assert_eq(result[4], 0)
}

///|
test "pad_to_length shorter" {
  let samples = [10, 20, 30, 40, 50]
  let result = pad_to_length(samples, 3)

  assert_eq(result.length(), 3)
  assert_eq(result[0], 10)
  assert_eq(result[1], 20)
  assert_eq(result[2], 30)
}

///|
test "cross_correlation_zero_lag identical" {
  let a = [100, 200, 300, 400]
  let b = [100, 200, 300, 400]
  let corr = cross_correlation_zero_lag(a, b)

  // Correlation of identical signals should be positive and large
  assert_true(corr > 0.0)
}

///|
test "cross_correlation_zero_lag opposite" {
  let a = [100, 200, 300, 400]
  let b = [-100, -200, -300, -400]
  let corr = cross_correlation_zero_lag(a, b)

  // Correlation of opposite signals should be negative
  assert_true(corr < 0.0)
}
