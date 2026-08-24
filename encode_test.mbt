// Tests for WAV encoding

///|
test "encode 16-bit mono WAV roundtrip" {
  let samples = [100, -100, 200, -200]
  let info = make_wav_info(1, 1, 44100, 88200, 2, 16, 8)

  let encoded = encode(make_audio_data(samples, info))
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
  let info = make_wav_info(1, 1, 22050, 22050, 1, 8, 4)

  let encoded = encode(make_audio_data(samples, info))
  let decoded = decode(encoded)

  assert_true(decoded is Ok(_))

  match decoded {
    Ok(audio) => {
      assert_eq(audio.info.bits_per_sample, 8)
      assert_eq(audio.samples.length(), 4)
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
  let info = make_wav_info(1, 2, 44100, 176400, 4, 16, 8)

  let encoded = encode(make_audio_data(samples, info))
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
  let info = make_wav_info(1, 1, 44100, 132300, 3, 24, 12)

  let encoded = encode(make_audio_data(samples, info))
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
