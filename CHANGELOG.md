# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
