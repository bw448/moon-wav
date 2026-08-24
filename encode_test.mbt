// Tests for WAV encoding

///|
test "encode 16-bit mono WAV roundtrip" {
  let samples = [100, -100, 200, -200]
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate: 44100,
    byte_rate: 88200,
    block_align: 2,
    bits_per_sample: 16,
    data_size: 8,
  }

  let encoded = encode({ samples, info })
  let decoded = decode(encoded)

  assert_true(decoded is Ok(_))

  match decoded {
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
test "encode 8-bit mono WAV roundtrip" {
  let samples = [0, 50, -50, 100]
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate: 22050,
    byte_rate: 22050,
    block_align: 1,
    bits_per_sample: 8,
    data_size: 4,
  }

  let encoded = encode({ samples, info })
  let decoded = decode(encoded)

  assert_true(decoded is Ok(_))

  match decoded {
    Ok(audio) => {
      assert_eq(audio.info.bits_per_sample, 8)
      assert_eq(audio.samples.length(), 4)
      // 8-bit: encode (sample + 128), decode (byte - 128)
      // 0 -> 128 -> 0, 50 -> 178 -> 50, -50 -> 78 -> -50, 100 -> 228 -> 100
      assert_eq(audio.samples[0], 0)
      assert_eq(audio.samples[1], 50)
      assert_eq(audio.samples[2], -50)
      assert_eq(audio.samples[3], 100)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "encode 16-bit stereo WAV roundtrip" {
  let samples = [100, 200, -100, -200]
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 2,
    sample_rate: 44100,
    byte_rate: 176400,
    block_align: 4,
    bits_per_sample: 16,
    data_size: 8,
  }

  let encoded = encode({ samples, info })
  let decoded = decode(encoded)

  assert_true(decoded is Ok(_))

  match decoded {
    Ok(audio) => {
      assert_eq(audio.info.num_channels, 2)
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
test "encode_with_format helper" {
  let samples = [1000, -1000, 2000, -2000]
  let encoded = encode_with_format(samples, 1, 44100, 16)
  let decoded = decode(encoded)

  assert_true(decoded is Ok(_))

  match decoded {
    Ok(audio) => {
      assert_eq(audio.info.num_channels, 1)
      assert_eq(audio.info.sample_rate, 44100)
      assert_eq(audio.info.bits_per_sample, 16)
      assert_eq(audio.samples.length(), 4)
      assert_eq(audio.samples[0], 1000)
      assert_eq(audio.samples[1], -1000)
      assert_eq(audio.samples[2], 2000)
      assert_eq(audio.samples[3], -2000)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "encode 24-bit mono WAV roundtrip" {
  let samples = [100000, -100000, 200000, -200000]
  let info : WavInfo = {
    audio_format: 1,
    num_channels: 1,
    sample_rate: 44100,
    byte_rate: 132300,
    block_align: 3,
    bits_per_sample: 24,
    data_size: 12,
  }

  let encoded = encode({ samples, info })
  let decoded = decode(encoded)

  assert_true(decoded is Ok(_))

  match decoded {
    Ok(audio) => {
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
