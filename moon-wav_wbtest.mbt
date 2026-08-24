// Whitebox tests for WAV decoder internals

///|
test "validate_riff_header valid" {
  let data = Bytes::from_array([
    b'R', b'I', b'F', b'F', 0, 0, 0, 0, b'W', b'A', b'V', b'E',
  ])
  let result = validate_riff_header(data)
  assert_true(result is Ok(_))
}

///|
test "validate_riff_header invalid magic" {
  let data = Bytes::from_array([
    b'N', b'O', b'T', b'R', 0, 0, 0, 0, b'W', b'A', b'V', b'E',
  ])
  let result = validate_riff_header(data)
  assert_true(result is Err(InvalidHeader))
}

///|
test "validate_riff_header too short" {
  let data = Bytes::from_array([b'R', b'I', b'F', b'F'])
  let result = validate_riff_header(data)
  assert_true(result is Err(InvalidHeader))
}

///|
test "parse_chunk_header valid" {
  let view = Bytes::from_array([b'f', b'm', b't', b' ', 16, 0, 0, 0])
  let result = parse_chunk_header(view, 0)

  match result {
    Ok((id, size)) => {
      assert_eq(id[0], b'f')
      assert_eq(id[1], b'm')
      assert_eq(id[2], b't')
      assert_eq(id[3], b' ')
      assert_eq(size, 16)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode_pcm_8bit basic" {
  let data = Bytes::from_array([128, 255, 0, 178])
  let result = decode_pcm_8bit(data)

  match result {
    Ok(samples) => {
      assert_eq(samples.length(), 4)
      assert_eq(samples[0], 0) // 128 - 128
      assert_eq(samples[1], 127) // 255 - 128
      assert_eq(samples[2], -128) // 0 - 128
      assert_eq(samples[3], 50) // 178 - 128
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode_pcm_16bit basic" {
  let data = Bytes::from_array([100, 0, 156, 255, 200, 0, 56, 255])
  let result = decode_pcm_16bit(data)

  match result {
    Ok(samples) => {
      assert_eq(samples.length(), 4)
      assert_eq(samples[0], 100)
      assert_eq(samples[1], -100)
      assert_eq(samples[2], 200)
      assert_eq(samples[3], -200)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode_pcm_24bit basic" {
  let data = Bytes::from_array([
    0xA0, 0x86, 0x01, // 100000
     0x60, 0x79, 0xFE, // -100000
  ])
  let result = decode_pcm_24bit(data)

  match result {
    Ok(samples) => {
      assert_eq(samples.length(), 2)
      assert_eq(samples[0], 100000)
      assert_eq(samples[1], -100000)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode_pcm_32bit basic" {
  let data = Bytes::from_array([
    0x40, 0x42, 0x0F, 0x00, // 1000000
     0xC0, 0xBD, 0xF0, 0xFF, // -1000000
  ])
  let result = decode_pcm_32bit(data)

  match result {
    Ok(samples) => {
      assert_eq(samples.length(), 2)
      assert_eq(samples[0], 1000000)
      assert_eq(samples[1], -1000000)
    }
    Err(_) => assert_true(false)
  }
}
