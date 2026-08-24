// Example: Complete WAV library demonstration
//
// Run with: moon run cmd/main

///|
fn main {
  println("=== moon-wav Library Demo ===")
  println("")

  // 1. Generate a sine wave and encode to WAV
  demo_generate_and_encode()

  // 2. Decode and analyze
  demo_decode_and_analyze()

  // 3. Audio processing pipeline
  demo_processing_pipeline()

  // 4. Format conversion
  demo_format_conversion()

  // 5. Validation
  demo_validation()
}

///|
fn demo_generate_and_encode() -> Unit {
  println("--- 1. Generate & Encode ---")

  // Generate a 440Hz sine wave (A4 note), 0.5 seconds
  let audio = @lib.generate_sine_wav(440.0, 16000.0, 44100, 0.5, 16)
  println(
    "Generated " + audio.samples.length().to_string() + " samples at 440Hz",
  )

  // Encode to WAV format
  let wav_bytes = @lib.encode(audio)
  println("Encoded to WAV: " + wav_bytes.length().to_string() + " bytes")

  // Verify by decoding
  match @lib.decode(wav_bytes) {
    Ok(decoded) =>
      println(
        "Decoded successfully: " +
        decoded.samples.length().to_string() +
        " samples",
      )
    Err(_) => println("Decode failed!")
  }
  println("")
}

///|
fn demo_decode_and_analyze() -> Unit {
  println("--- 2. Decode & Analyze ---")

  // Create a test WAV
  let audio = @lib.generate_sine_wav(1000.0, 20000.0, 44100, 0.2, 16)
  let wav_data = @lib.encode(audio)

  match @lib.decode(wav_data) {
    Ok(decoded) => {
      // Format info
      let info_str = @lib.format_wav_info(decoded.info)
      println(info_str)

      // Analysis
      let analysis = @lib.analyze(decoded, 100)
      println("Peak amplitude: " + analysis.peak.to_string())
      println("RMS level: " + analysis.rms.to_string())
      println("Zero crossings: " + analysis.zero_crossings.to_string())
      println("Has clipping: " + analysis.has_clipping.to_string())
      println(
        "Silence ratio: " + (analysis.silence_ratio * 100.0).to_string() + "%",
      )
    }
    Err(_) => println("Decode failed!")
  }
  println("")
}

///|
fn demo_processing_pipeline() -> Unit {
  println("--- 3. Processing Pipeline ---")

  // Generate source audio
  let audio = @lib.generate_sine_wav(440.0, 16000.0, 44100, 0.3, 16)
  println("Original: " + audio.samples.length().to_string() + " samples")

  // Apply effects chain
  let processed = @lib.fade_in(audio.samples, 2205) // 50ms fade in
  let processed = @lib.fade_out(processed, 2205) // 50ms fade out
  let processed = @lib.adjust_volume(processed, 0.8) // 80% volume
  println(
    "After fade in/out + volume: " + processed.length().to_string() + " samples",
  )

  // Reverse effect
  let reversed = @lib.reverse(processed)
  println("After reverse: " + reversed.length().to_string() + " samples")

  // Trim to first 10000 samples
  let trimmed = @lib.trim(processed, 0, 10000)
  println("After trim: " + trimmed.length().to_string() + " samples")
  println("")
}

///|
fn demo_format_conversion() -> Unit {
  println("--- 4. Format Conversion ---")

  // Create stereo audio
  let left = @lib.generate_sine(440.0, 16000.0, 44100, 0.1)
  let right = @lib.generate_sine(880.0, 16000.0, 44100, 0.1)
  let stereo = @lib.combine_stereo(left, right)
  println("Stereo: " + stereo.length().to_string() + " samples")

  // Convert to mono
  match @lib.convert_channels(stereo, 2, 1) {
    Ok(mono) => println("Mono: " + mono.length().to_string() + " samples")
    Err(_) => println("Conversion failed!")
  }

  // Bit depth conversion
  let samples_16 = [1000, -1000, 2000, -2000]
  match @lib.convert_bit_depth(samples_16, 16, 8) {
    Ok(samples_8) =>
      println("16-bit to 8-bit: " + samples_8.length().to_string() + " samples")
    Err(_) => println("Conversion failed!")
  }

  // Resample
  let samples = @lib.generate_sine(440.0, 16000.0, 44100, 0.1)
  let resampled = @lib.resample(samples, 44100, 22050, 1)
  println(
    "Resampled 44100->22050: " + resampled.length().to_string() + " samples",
  )
  println("")
}

///|
fn demo_validation() -> Unit {
  println("--- 5. Validation ---")

  // Create a valid WAV
  let audio = @lib.generate_sine_wav(440.0, 16000.0, 44100, 0.1, 16)
  let wav_data = @lib.encode(audio)

  let result = @lib.validate(wav_data)
  println("Valid: " + result.is_valid.to_string())
  println("Warnings: " + result.warnings.length().to_string())

  // Validate invalid data
  let invalid = Bytes::from_array([0, 0, 0, 0, 0, 0])
  let result2 = @lib.validate(invalid)
  println("Invalid data - Valid: " + result2.is_valid.to_string())
  match result2.error {
    Some(msg) => println("Error: " + msg)
    None => println("No error")
  }
  println("")
}
