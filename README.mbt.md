# moon-wav

A native MoonBit WAV audio decoding library.

## Features

- **WAV File Parsing**: Parse RIFF headers, fmt chunks, and data chunks
- **PCM Audio Decoding**: Support for 8-bit, 16-bit, and 24-bit PCM audio
- **Channel Support**: Mono and stereo audio
- **Format Conversion**: Convert between bit depths and channel configurations
- **Audio Operations**: Trim, concat, volume adjust, mix, fade in/out, reverse
- **Statistics**: Peak amplitude and RMS level calculation

## Installation

```bash
moon add username/moon-wav
```

## Quick Start

```moonbit nocheck
// Decode a WAV file
// ... your WAV file bytes
///|
let wav_data = match decode(wav_data) {
  Ok(audio) => {
    println("Sample Rate: " + audio.info.sample_rate.to_string())
    println("Channels: " + audio.info.num_channels.to_string())
    println("Samples: " + audio.samples.length().to_string())
  }
  Err(e) => println("Error: " + e.to_string())
}
```

## API Reference

### Core Types

#### `WavInfo`
Represents the format information of a WAV file.

```moonbit nocheck
///|
pub struct WavInfo {
  audio_format : Int // 1 = PCM, 3 = IEEE float
  num_channels : Int // 1 = mono, 2 = stereo
  sample_rate : Int // Sample rate in Hz
  byte_rate : Int // Byte rate
  block_align : Int // Block align
  bits_per_sample : Int // 8, 16, or 24
  data_size : Int // Data size in bytes
}
```

#### `AudioData`
Represents decoded audio data with format information.

```moonbit nocheck
///|
pub struct AudioData {
  samples : Array[Int] // Decoded samples (32-bit signed)
  info : WavInfo // Format information
}
```

#### `WavError`
Errors that can occur during WAV decoding.

```moonbit nocheck
///|
pub enum WavError {
  InvalidHeader
  UnsupportedFormat
  CorruptedData
  InvalidChunk
}
```

### Decoding Functions

#### `decode(data : Bytes) -> Result[AudioData, WavError]`
Decode a WAV file from bytes.

#### `get_info(data : Bytes) -> Result[WavInfo, WavError]`
Get WAV file information without decoding audio data.

### Conversion Functions

#### `convert_bit_depth(samples, from_bits, to_bits) -> Result[Array[Int], WavError]`
Convert audio samples between bit depths (8, 16, 24).

#### `convert_channels(samples, from_channels, to_channels) -> Result[Array[Int], WavError]`
Convert between mono and stereo.

#### `resample(samples, from_rate, to_rate, num_channels) -> Array[Int]`
Resample audio to a different sample rate using linear interpolation.

### Audio Operations

#### `trim(samples, start, end) -> Array[Int]`
Trim audio samples to a specified range.

#### `concat(a, b) -> Array[Int]`
Concatenate two audio sample arrays.

#### `adjust_volume(samples, factor) -> Array[Int]`
Adjust volume by a multiplier (1.0 = no change).

#### `mix(a, b) -> Array[Int]`
Mix two audio streams by averaging.

#### `fade_in(samples, fade_samples) -> Array[Int]`
Apply fade in effect.

#### `fade_out(samples, fade_samples) -> Array[Int]`
Apply fade out effect.

#### `reverse(samples) -> Array[Int]`
Reverse audio samples.

#### `get_peak_amplitude(samples) -> Int`
Get peak amplitude (absolute value).

#### `get_rms_level(samples) -> Double`
Get RMS (Root Mean Square) level.

## Examples

### Decode and Display Information

```moonbit nocheck
///|
fn main { // ... load WAV file
  let wav_data = match decode(wav_data) {
    Ok(audio) => {
      println("Sample Rate: " + audio.info.sample_rate.to_string() + " Hz")
      println("Channels: " + audio.info.num_channels.to_string())
      println("Bits: " + audio.info.bits_per_sample.to_string())
      println("Samples: " + audio.samples.length().to_string())
    }
    Err(_) => println("Failed to decode")
  }
}
```

### Convert 16-bit to 8-bit

```moonbit nocheck
match decode(wav_data) {
  Ok(audio) => {
    match convert_bit_depth(audio.samples, 16, 8) {
      Ok(converted) => println("Converted " + converted.length().to_string() + " samples")
      Err(_) => println("Conversion failed")
    }
  }
  Err(_) => ()
}
```

### Adjust Volume

```moonbit nocheck
match decode(wav_data) {
  Ok(audio) => {
    let quieter = adjust_volume(audio.samples, 0.5) // 50% volume
    println("Processed " + quieter.length().to_string() + " samples")
  }
  Err(_) => ()
}
```

## Building

```bash
# Build the library
moon build

# Run tests
moon test

# Run the example
moon run cmd/main
```

## License

Apache-2.0

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
