# 🎵 moon-wav

**MoonBit 原生 WAV 音频库**

A native MoonBit WAV audio library.

一个纯 MoonBit 实现的 WAV 音频库，支持解码、编码、格式转换、音频操作、波形生成和音频分析。

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![mooncakes.io](https://img.shields.io/badge/mooncakes.io-bw448%2Fmoon--wav-green.svg)](https://mooncakes.io/docs/bw448/moon-wav)

## ✨ Features / 功能特性

- **WAV 解码** - 支持 8/16/24/32 位 PCM 和 IEEE 754 浮点格式
- **WAV 编码** - 将音频数据编码为标准 WAV 文件
- **格式验证** - 详细的 WAV 文件格式检查和警告
- **格式转换** - 位深转换、声道转换、采样率重采样
- **音频操作** - 裁剪、拼接、音量调整、混音、淡入淡出、反转
- **音频效果** - 回声、延迟、归一化、软限幅、低通/高通滤波
- **波形生成** - 正弦波、方波、锯齿波、三角波、噪声、啁啾
- **音频分析** - 峰值、RMS、直流偏移、过零率、削波检测、静音检测
- **工具函数** - 声道分离/合并、重复、填充、交叉相关

## 📦 Installation

```bash
moon add bw448/moon-wav
```

## 🚀 Quick Start

```moonbit
fn main {
  // Generate a 440Hz sine wave
  let audio = generate_sine_wav(440.0, 16000.0, 44100, 1.0, 16)

  // Encode to WAV format
  let wav_bytes = encode(audio)
  println("Generated " + wav_bytes.length().to_string() + " bytes")

  // Decode and analyze
  match decode(wav_bytes) {
    Ok(decoded) => {
      let analysis = analyze(decoded, 100)
      println("Peak: " + analysis.peak.to_string())
      println("RMS: " + analysis.rms.to_string())
    }
    Err(_) => println("Decode failed")
  }
}
```

## 📚 API Reference

### Core Types

#### `WavInfo`

```moonbit
pub struct WavInfo {
  audio_format : Int    // 1 = PCM, 3 = IEEE float
  num_channels : Int    // 1 = mono, 2 = stereo
  sample_rate : Int     // Sample rate in Hz (e.g., 44100)
  byte_rate : Int       // Byte rate
  block_align : Int     // Block align
  bits_per_sample : Int // 8, 16, 24, or 32
  data_size : Int       // Data size in bytes
}
```

#### `AudioData`

```moonbit
pub struct AudioData {
  samples : Array[Int]  // Decoded samples (32-bit signed integers)
  info : WavInfo        // Format information
}
```

#### `WavError`

```moonbit
pub enum WavError {
  InvalidHeader
  UnsupportedFormat
  CorruptedData
  InvalidChunk
}
```

#### `ValidationResult`

```moonbit
pub struct ValidationResult {
  is_valid : Bool
  warnings : Array[String]
  error : String?
}
```

#### `AudioAnalysis`

```moonbit
pub struct AudioAnalysis {
  duration_sec : Double
  samples_per_channel : Int
  peak : Int
  rms : Double
  dc_offset : Double
  zero_crossings : Int
  has_clipping : Bool
  clipped_samples : Int
  is_silent : Bool
  silence_ratio : Double
}
```

### Decoding Functions

| Function | Description |
|----------|-------------|
| `decode(data : Bytes) -> Result[AudioData, WavError]` | Decode a WAV file (PCM & IEEE float) |
| `get_info(data : Bytes) -> Result[WavInfo, WavError]` | Get WAV info without decoding |

### Encoding Functions

| Function | Description |
|----------|-------------|
| `encode(audio : AudioData) -> Bytes` | Encode audio data to WAV format |
| `encode_with_format(samples, num_channels, sample_rate, bits_per_sample) -> Bytes` | Encode with specified format |

### Validation Functions

| Function | Description |
|----------|-------------|
| `validate(data : Bytes) -> ValidationResult` | Validate WAV file structure |

### Conversion Functions

| Function | Description |
|----------|-------------|
| `convert_bit_depth(samples, from_bits, to_bits) -> Result[Array[Int], WavError]` | Convert bit depth |
| `convert_channels(samples, from_channels, to_channels) -> Result[Array[Int], WavError]` | Convert channels |
| `resample(samples, from_rate, to_rate, num_channels) -> Array[Int]` | Resample audio |

### Audio Operations

| Function | Description |
|----------|-------------|
| `trim(samples, start, end) -> Array[Int]` | Trim audio |
| `concat(a, b) -> Array[Int]` | Concatenate audio |
| `adjust_volume(samples, factor) -> Array[Int]` | Adjust volume |
| `mix(a, b) -> Array[Int]` | Mix two streams |
| `fade_in(samples, fade_samples) -> Array[Int]` | Fade in |
| `fade_out(samples, fade_samples) -> Array[Int]` | Fade out |
| `reverse(samples) -> Array[Int]` | Reverse audio |
| `get_peak_amplitude(samples) -> Int` | Get peak amplitude |
| `get_rms_level(samples) -> Double` | Get RMS level |

### Audio Effects

| Function | Description |
|----------|-------------|
| `echo(samples, delay_samples, decay) -> Array[Int]` | Echo effect |
| `delay(samples, delay_samples, mix) -> Array[Int]` | Delay effect |
| `normalize(samples, target_peak) -> Array[Int]` | Normalize to target peak |
| `soft_clip(samples, threshold) -> Array[Int]` | Soft clipping |
| `remove_dc_offset(samples) -> Array[Int]` | Remove DC offset |
| `low_pass_filter(samples, window_size) -> Array[Int]` | Low-pass filter |
| `high_pass_filter(samples, window_size) -> Array[Int]` | High-pass filter |
| `reverse_reverb(samples, fade_samples) -> Array[Int]` | Reverse reverb |

### Waveform Generators

| Function | Description |
|----------|-------------|
| `generate_sine(freq, amp, rate, duration) -> Array[Int]` | Sine wave |
| `generate_square(freq, amp, rate, duration) -> Array[Int]` | Square wave |
| `generate_sawtooth(freq, amp, rate, duration) -> Array[Int]` | Sawtooth wave |
| `generate_triangle(freq, amp, rate, duration) -> Array[Int]` | Triangle wave |
| `generate_noise(amp, rate, duration, seed) -> Array[Int]` | White noise |
| `generate_chirp(start_freq, end_freq, amp, rate, duration) -> Array[Int]` | Frequency sweep |
| `generate_silence(rate, duration) -> Array[Int]` | Silence |
| `generate_sine_wav(freq, amp, rate, duration, bits) -> AudioData` | Sine as AudioData |

### Audio Analysis

| Function | Description |
|----------|-------------|
| `analyze(audio, silence_threshold) -> AudioAnalysis` | Full analysis |
| `calculate_dc_offset(samples) -> Double` | DC offset |
| `count_zero_crossings(samples) -> Int` | Zero crossings |
| `count_clipped_samples(samples, min, max) -> Int` | Clipped samples |
| `count_silent_samples(samples, threshold) -> Int` | Silent samples |
| `format_analysis(analysis) -> String` | Format analysis as string |

### Utility Functions

| Function | Description |
|----------|-------------|
| `format_wav_info(info) -> String` | Format WAV info as string |
| `split_stereo(samples) -> (Array[Int], Array[Int])` | Split stereo to L/R |
| `combine_stereo(left, right) -> Array[Int]` | Combine L/R to stereo |
| `get_duration(audio) -> Double` | Get duration in seconds |
| `get_frame_count(audio) -> Int` | Get frame count |
| `extract_channel(samples, num_channels, channel) -> Array[Int]` | Extract one channel |
| `mix_multiple(streams) -> Array[Int]` | Mix multiple streams |
| `repeat(samples, times) -> Array[Int]` | Repeat audio |
| `pad_to_length(samples, target_length) -> Array[Int]` | Pad with silence |
| `cross_correlation_zero_lag(a, b) -> Double` | Cross-correlation |

## ⚠️ Limitations / 功能边界

### Supported Formats / 支持的格式

| Format | Decode | Encode |
|--------|--------|--------|
| PCM 8-bit unsigned | ✅ | ✅ |
| PCM 16-bit signed LE | ✅ | ✅ |
| PCM 24-bit signed LE | ✅ | ✅ |
| PCM 32-bit signed LE | ✅ | ✅ |
| IEEE 754 32-bit float | ✅ | ❌ |
| ADPCM, A-law, μ-law | ❌ | ❌ |
| Compressed formats | ❌ | ❌ |

### Channel Support / 声道支持

| Channels | Support |
|----------|---------|
| Mono (1ch) | ✅ Full |
| Stereo (2ch) | ✅ Full |
| Multi-channel (3+) | ⚠️ Partial (decode only) |

### Sample Rate / 采样率

- Any sample rate from 1 Hz to 192,000 Hz
- Resampling uses linear interpolation (not band-limited)

### Known Limitations / 已知限制

1. **Only standard WAV files** - RIFF/WAVE format only, no RF64 or BWF
2. **No compressed formats** - ADPCM, A-law, μ-law not supported
3. **IEEE float encode not supported** - Can decode but not encode float WAV
4. **Linear interpolation resampling** - May introduce aliasing at extreme ratios
5. **No metadata chunks** - LIST, INFO chunks are ignored
6. **32-bit integer samples** - All samples stored as 32-bit signed integers internally

## 📝 Examples

### Generate and Encode WAV

```moonbit
let audio = generate_sine_wav(440.0, 16000.0, 44100, 1.0, 16)
let wav_bytes = encode(audio)
println("WAV file: " + wav_bytes.length().to_string() + " bytes")
```

### Validate WAV File

```moonbit
let result = validate(wav_data)
if result.is_valid {
  println("Valid WAV file")
} else {
  println("Invalid: " + result.error.to_string())
}
```

### Audio Analysis

```moonbit
match decode(wav_data) {
  Ok(audio) => {
    let analysis = analyze(audio, 100)
    println("Duration: " + analysis.duration_sec.to_string() + "s")
    println("Peak: " + analysis.peak.to_string())
    println("Clipping: " + analysis.has_clipping.to_string())
  }
  Err(_) => ()
}
```

### Processing Pipeline

```moonbit
let audio = generate_sine_wav(440.0, 16000.0, 44100, 1.0, 16)
let processed = fade_in(audio.samples, 4410) // 100ms fade in
let processed = fade_out(processed, 4410) // 100ms fade out
let processed = normalize(processed, 32000) // Normalize
let encoded = encode({ samples: processed, info: audio.info })
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
