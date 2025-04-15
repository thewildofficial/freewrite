# Freewrite

A minimalist, distraction-free writing app for macOS that helps you focus on your thoughts.

![App Demo](https://i.imgur.com/2ucbtff.gif)

## Features

- 🎯 **Distraction-Free Writing** - Clean interface with just you and your words
- ✨ **Zen Mode** - Ultra-focused writing experience with centered text and minimal UI
- ⏲️ **Writing Timer** - Built-in configurable timer to track your writing sessions
- 🎨 **Customizable Appearance** - Choose from system fonts or included Lato font family
- 💾 **Auto-Saving** - Your work is automatically saved as you write
- 🤖 **AI Integration** - One-click analysis of your writing with ChatGPT or Claude
- 📂 **Version History** - Browse and manage your past writing sessions
- 🎯 **Custom Save Location** - Choose where to store your writing files
- 🌗 **Perfectly Synced Theme Transitions** - When you toggle between light and dark mode, both the window and the text area update their appearance at the exact same time for a smooth, unified experience.

## Download

Since this is a fork, you'll have to build it yourself :)

If there's enough demand, I'll set up a release version.

## Building from Source

### Prerequisites
- Xcode 15.0 or later
- macOS 13.5 or later
- Git

### Steps to Build

1. Clone the repository:
   ```bash
   git clone https://github.com/thewildofficial/freewrite.git
   cd freewrite
   ```

2. Open the project in Xcode:
   ```bash
   open freewrite.xcodeproj
   ```

3. Select your development team in Xcode (if needed):
   - Click on the project in the navigator
   - Select the "freewrite" target
   - Under "Signing & Capabilities", choose your team

4. Build and run:
   - Select "Product > Build" (⌘B) to build
   - Select "Product > Run" (⌘R) to run

The app will build and launch on your Mac.

## Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit (`git commit -m 'Add amazing feature'`)
5. Push to your branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

Please ensure your PR description clearly describes the changes and their benefits.

Make changes on a PR and I'll run on my end and then build a new version.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to [Farza](https://github.com/farzaa) for creating and maintaining the original version
- Built with SwiftUI for macOS
- Uses the Lato font family under the SIL Open Font License, and other fonts too
