# 🎵 moon-wav

**MoonBit 原生 WAV 音频解码库**

A native MoonBit WAV audio decoding library.

一个纯 MoonBit 实现的 WAV 音频解码库，支持 PCM 解码、格式转换、音频操作等功能。

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![mooncakes.io](https://img.shields.io/badge/mooncakes.io-bw448%2Fmoon--wav-green.svg)](https://mooncakes.io/docs/bw448/moon-wav)

## ✨ Features / 功能特性

- **WAV 文件解析** - 解析 RIFF 头部、fmt 块、data 块
- **PCM 音频解码** - 支持 8 位、16 位、24 位、32 位 PCM 音频
- **IEEE float 解码** - 支持 IEEE 754 32 位浮点音频
- **WAV 编码** - 将音频数据编码为 WAV 文件
- **声道支持** - 单声道和立体声
- **格式转换** - 位深转换、声道转换、采样率转换
- **音频操作** - 裁剪、拼接、音量调整、混音、淡入淡出、反转
- **统计分析** - 峰值振幅和 RMS 电平计算

## 📦 Installation

```bash
moon add bw448/moon-wav
```

## 🚀 Quick Start

```moonbit
fn main {
  // Create or load WAV data
  let wav_data = create_sample_wav()

  // Decode the WAV file
  match decode(wav_data) {
    Ok(audio) => {
      println("Sample Rate: " + audio.info.sample_rate.to_string() + " Hz")
      println("Channels: " + audio.info.num_channels.to_string())
      println("Samples: " + audio.samples.length().to_string())
    }
    Err(_) => println("Failed to decode")
  }
}
```

## 📚 API Reference

### Core Types

#### `WavInfo`

Represents the format information of a WAV file.

```moonbit
pub struct WavInfo {
  audio_format : Int    // 1 = PCM, 3 = IEEE float
  num_channels : Int    // 1 = mono, 2 = stereo
  sample_rate : Int     // Sample rate in Hz (e.g., 44100)
  byte_rate : Int       // Byte rate
  block_align : Int     // Block align
  bits_per_sample : Int // 8, 16, or 24
  data_size : Int       // Data size in bytes
}
```

#### `AudioData`

Represents decoded audio data with format information.

```moonbit
pub struct AudioData {
  samples : Array[Int]  // Decoded samples (32-bit signed integers)
  info : WavInfo        // Format information
}
```

#### `WavError`

Errors that can occur during WAV decoding.

```moonbit
pub enum WavError {
  InvalidHeader
  UnsupportedFormat
  CorruptedData
  InvalidChunk
}
```

### Decoding Functions

| Function | Description |
|----------|-------------|
| `decode(data : Bytes) -> Result[AudioData, WavError]` | Decode a WAV file from bytes (PCM & IEEE float) |
| `get_info(data : Bytes) -> Result[WavInfo, WavError]` | Get WAV file information without decoding audio data |

### Encoding Functions

| Function | Description |
|----------|-------------|
| `encode(audio : AudioData) -> Bytes` | Encode audio data to WAV format |
| `encode_with_format(samples, num_channels, sample_rate, bits_per_sample) -> Bytes` | Encode samples with specified format |

### Conversion Functions

| Function | Description |
|----------|-------------|
| `convert_bit_depth(samples, from_bits, to_bits)` | Convert between bit depths (8, 16, 24) |
| `convert_channels(samples, from_channels, to_channels)` | Convert between mono and stereo |
| `resample(samples, from_rate, to_rate, num_channels)` | Resample audio to a different sample rate |

### Audio Operations

| Function | Description |
|----------|-------------|
| `trim(samples, start, end)` | Trim audio samples to a specified range |
| `concat(a, b)` | Concatenate two audio sample arrays |
| `adjust_volume(samples, factor)` | Adjust volume by a multiplier (1.0 = no change) |
| `mix(a, b)` | Mix two audio streams by averaging |
| `fade_in(samples, fade_samples)` | Apply fade in effect |
| `fade_out(samples, fade_samples)` | Apply fade out effect |
| `reverse(samples)` | Reverse audio samples |
| `get_peak_amplitude(samples)` | Get peak amplitude (absolute value) |
| `get_rms_level(samples)` | Get RMS (Root Mean Square) level |

## 📝 Examples

### Decode and Display Information

```moonbit
fn main {
  let wav_data = // ... load WAV file
  match decode(wav_data) {
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

```moonbit
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

```moonbit
match decode(wav_data) {
  Ok(audio) => {
    let quieter = adjust_volume(audio.samples, 0.5) // 50% volume
    println("Processed " + quieter.length().to_string() + " samples")
  }
  Err(_) => ()
}
```

### Encode WAV File

```moonbit
// Encode samples directly to WAV format
let samples = [1000, -1000, 2000, -2000]
let wav_bytes = encode_with_format(samples, 1, 44100, 16)
println("Encoded " + wav_bytes.length().to_string() + " bytes")
```

## 🔨 Building

```bash
# Build the library
moon build

# Run tests
moon test

# Run the example
moon run cmd/main
```

## 📄 License

Apache-2.0

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
