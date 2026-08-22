// Example: Decode a WAV file and display its information
//
// Run with: moon run cmd/main

///|
fn main {
  // Create a sample WAV file for demonstration
  let wav_data = create_sample_wav()

  // Decode the WAV file
  match @lib.decode(wav_data) {
    Ok(audio) => {
      println("=== WAV File Information ===")
      println("Audio Format: PCM")
      println("Channels: " + audio.info.num_channels.to_string())
      println("Sample Rate: " + audio.info.sample_rate.to_string() + " Hz")
      println("Bits Per Sample: " + audio.info.bits_per_sample.to_string())
      println("Data Size: " + audio.info.data_size.to_string() + " bytes")
      println("")

      println("=== Audio Data ===")
      println("Total Samples: " + audio.samples.length().to_string())
      println("")

      // Display first 10 samples
      println("First 10 samples:")
      let mut i = 0
      while i < 10 && i < audio.samples.length() {
        println(
          "  Sample " + i.to_string() + ": " + audio.samples[i].to_string(),
        )
        i = i + 1
      }
      println("")

      // Calculate some statistics
      let peak = @lib.get_peak_amplitude(audio.samples)
      let rms = @lib.get_rms_level(audio.samples)
      println("=== Statistics ===")
      println("Peak Amplitude: " + peak.to_string())
      println("RMS Level: " + rms.to_string())
    }
    Err(_) => println("Error decoding WAV file")
  }
}

///|
/// Create a sample WAV file with a simple sine wave
fn create_sample_wav() -> Bytes {
  let buf = Buffer(size_hint=1024)
  let num_samples = 100
  let sample_rate = 44100
  let bits_per_sample = 16

  // RIFF header
  buf.write_bytes(b"RIFF")
  let data_size = num_samples * (bits_per_sample / 8)
  let file_size = 36 + data_size
  buf.write_int_le(file_size)
  buf.write_bytes(b"WAVE")

  // fmt chunk
  buf.write_bytes(b"fmt ")
  buf.write_int_le(16) // chunk size
  buf.write_int16_le(Int16::from_int(1)) // PCM format
  buf.write_int16_le(Int16::from_int(1)) // mono
  buf.write_int_le(sample_rate)
  let byte_rate = sample_rate * 1 * (bits_per_sample / 8)
  buf.write_int_le(byte_rate)
  let block_align = 1 * (bits_per_sample / 8)
  buf.write_int16_le(Int16::from_int(block_align))
  buf.write_int16_le(Int16::from_int(bits_per_sample))

  // data chunk
  buf.write_bytes(b"data")
  buf.write_int_le(data_size)

  // Generate a simple sine wave (440 Hz = A4 note)
  let frequency = 440.0
  let amplitude = 16000.0
  let pi = 3.141592653589793

  let mut i = 0
  while i < num_samples {
    let t = Double::from_int(i) / Double::from_int(sample_rate)
    let angle = 2.0 * pi * frequency * t
    // Use Taylor series approximation for sin
    let sin_val = angle -
      angle * angle * angle / 6.0 +
      angle * angle * angle * angle * angle / 120.0
    let sample = (amplitude * sin_val).to_int()
    let clamped = if sample < -32768 {
      -32768
    } else if sample > 32767 {
      32767
    } else {
      sample
    }
    buf.write_int16_le(Int16::from_int(clamped))
    i = i + 1
  }

  buf.to_bytes()
}
