// Tests for WAV validator

///|
test "validate valid 16-bit WAV" {
  let samples = [100, -100, 200, -200]
  let wav_data = create_test_wav(1, 44100, 16, samples)
  let result = validate(wav_data)

  assert_true(result.is_valid)
  assert_true(result.error is None)
}

///|
test "validate valid 8-bit WAV" {
  let samples = [0, 50, -50, 100]
  let wav_data = create_test_wav(1, 22050, 8, samples)
  let result = validate(wav_data)

  assert_true(result.is_valid)
  assert_true(result.error is None)
}

///|
test "validate valid stereo WAV" {
  let samples = [100, 200, -100, -200]
  let wav_data = create_test_wav(2, 44100, 16, samples)
  let result = validate(wav_data)

  assert_true(result.is_valid)
  assert_true(result.error is None)
}

///|
test "validate invalid header" {
  let invalid_data = Bytes::from_array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  let result = validate(invalid_data)

  assert_true(!result.is_valid)
  assert_true(result.error is Some(_))
}

///|
test "validate too small file" {
  let tiny = Bytes::from_array([0, 0, 0, 0])
  let result = validate(tiny)

  assert_true(!result.is_valid)
}

///|
test "validate non-PCM format" {
  let buf = Buffer(size_hint=100)
  buf.write_bytes(b"RIFF")
  buf.write_int_le(36)
  buf.write_bytes(b"WAVE")
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16)
  buf.write_int16_le(2) // ADPCM format
  buf.write_int16_le(1)
  buf.write_int_le(44100)
  buf.write_int_le(88200)
  buf.write_int16_le(2)
  buf.write_int16_le(16)
  buf.write_bytes(b"data")
  buf.write_int_le(0)

  let result = validate(buf.to_bytes())

  // Should still be valid but with a warning
  assert_true(result.is_valid)
  assert_true(result.warnings.length() > 0)
}

///|
test "validate IEEE float format" {
  let buf = Buffer(size_hint=100)
  buf.write_bytes(b"RIFF")
  buf.write_int_le(36)
  buf.write_bytes(b"WAVE")
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16)
  buf.write_int16_le(3) // IEEE float
  buf.write_int16_le(1)
  buf.write_int_le(44100)
  buf.write_int_le(176400)
  buf.write_int16_le(4)
  buf.write_int16_le(32)
  buf.write_bytes(b"data")
  buf.write_int_le(0)

  let result = validate(buf.to_bytes())

  assert_true(result.is_valid)
  assert_true(result.error is None)
}
