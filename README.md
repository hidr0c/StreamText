# Stream Text

**Stream Text** is a Flutter-based tool that allows you to instantly send text to OBS via `.txt` or `.json` files, avoiding the default typing animation effect and improving overall control and customization.

## Features

- Input text and update `.txt` output instantly for OBS text sources
- No "typing" animation effect — clean and immediate display
- Optional `.json` output for dropdown/preset-based text management
- Simple UI for fast input and switching between presets
- Built with Flutter as part of personal learning and practice

## Why Stream Text?

This project was built to improve how text is displayed on stream, especially for use in upcoming tournaments and live events I'm working on. Compared to traditional OBS text updates via `.txt`, Stream Text offers:

- Faster control over what's shown
- More organized preset management via JSON
- Easier to integrate into production workflows

## How it works

- OBS reads from the generated `output.txt` file
- If using dropdowns or presets, the app also writes to `output.json`
- All file changes reflect immediately in OBS (no refresh or effect delay)

## Getting Started

```bash
git clone https://github.com/yourusername/stream-text.git
cd stream-text
flutter pub get
flutter run
