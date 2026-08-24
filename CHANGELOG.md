# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.0] - 2026-08-24

### Added

- **WAV validator**: `validate()` function with detailed error reporting and warnings
- **Audio analysis**: `analyze()` function with peak, RMS, DC offset, zero crossings, clipping detection, silence detection
- **Waveform generators**: sine, square, sawtooth, triangle, noise, chirp, silence
- **Audio effects**: echo, delay, normalize, soft clip, DC offset removal, low-pass filter, high-pass filter, reverse reverb
- **Utility functions**: format_wav_info, split_stereo, combine_stereo, get_duration, get_frame_count, extract_channel, mix_multiple, repeat, pad_to_length, cross_correlation
- **Whitebox tests**: Internal function tests for decode_pcm_8bit/16bit/24bit/32bit, validate_riff_header, parse_chunk_header
- **Edge case tests**: Empty data, truncated files, 24-bit stereo, cascading effects, filter behavior
- **Comprehensive examples**: Complete demo with generate, encode, decode, analyze, process, validate

### Changed

- Updated README with complete API reference for all modules
- Added limitations/boundary documentation (supported formats, channel support, known limits)
- Updated moon.mod version to 0.3.0

## [0.2.0] - 2026-08-24

### Added

- **32-bit PCM decoding**: Support for 32-bit signed integer PCM audio files
- **IEEE float decoding**: Support for IEEE 754 32-bit float WAV files (audio format 3)
- **WAV encoder**: `encode()` and `encode_with_format()` functions to write WAV files
- **Encoder tests**: Roundtrip tests for 8-bit, 16-bit, 24-bit encoding
- **Converter tests**: Unit tests for `convert_bit_depth`, `convert_channels`, `resample`
- **Operations tests**: Unit tests for `trim`, `concat`, `adjust_volume`, `mix`, `fade_in`, `fade_out`, `reverse`, `get_peak_amplitude`, `get_rms_level`
- **CHANGELOG.md**: This changelog file

### Changed

- `decode()` now supports both PCM (format 1) and IEEE float (format 3) WAV files
- `parse_fmt_chunk()` accepts audio format 1 (PCM) and 3 (IEEE float)

## [0.1.0] - 2026-08-22

### Added

- **WAV decoding**: Parse RIFF header, fmt chunk, data chunk
- **PCM decoding**: Support for 8-bit, 16-bit, 24-bit PCM audio
- **Format conversion**: `convert_bit_depth`, `convert_channels`, `resample`
- **Audio operations**: `trim`, `concat`, `adjust_volume`, `mix`, `fade_in`, `fade_out`, `reverse`
- **Statistics**: `get_peak_amplitude`, `get_rms_level`
- **CI**: GitHub Actions workflow for build, test, format check
- **Documentation**: README with API reference and examples
