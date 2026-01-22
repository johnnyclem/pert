# Pert

A Swift-based LLM prompt conditioning tool that enhances user prompts with expert analysis and detailed execution instructions.

## Overview

Pert is a macOS application that automatically detects and connects to local LLM services (LMStudio or Ollama) or remote OpenAI-compatible APIs. It applies a sophisticated conditioning system to transform basic user prompts into detailed, expert-level requests for optimal AI responses.

## Features

- **Automatic Service Detection**: Automatically detects local LMStudio (port 1234) and Ollama (port 11434) services
- **Smart Model Selection**: Intelligently selects the best available model (prioritizing models up to 30B parameters)
- **Dual Interface**: Both CLI and GUI versions available
- **Prompt Conditioning**: Enhances user prompts with expert analysis and detailed execution instructions
- **Clipboard Integration**: CLI version automatically copies results to clipboard
- **Manual Configuration**: Fallback to manual API configuration when local services aren't available

## Installation

### Prerequisites

- macOS 14.0 or later
- Swift 5.9 or later
- Xcode Command Line Tools

### Building from Source

```bash
git clone <repository-url>
cd pert
swift build
```

## Usage

### CLI Interface

```bash
# Run with a prompt
swift run PertCLI "Explain quantum computing in simple terms"

# The result will be displayed and automatically copied to clipboard
```

### GUI Interface

```bash
# Launch the GUI application
swift run PertGUI
```

The GUI provides:
- Split-pane interface for input and output
- Configuration settings for manual API setup
- Real-time processing feedback

## Local Service Support

Pert automatically detects and connects to:

### LMStudio
- **URL**: `http://localhost:1234/v1`
- **API Key**: `lm-studio`

### Ollama
- **URL**: `http://localhost:11434/v1`
- **API Key**: `ollama`

## Manual Configuration

When no local service is detected, Pert can connect to any OpenAI-compatible API:

1. Run PertCLI and enter your API details when prompted
2. Use the GUI settings panel to configure base URL and API key

## Model Selection Logic

Pert prioritizes models in this order (30B and under):
1. 30B → 27B → 20B → 14B → 13B → 11B → 8B → 7B → 3B
2. Falls back to first available model if no size-specific models found

## Architecture

```
Sources/
├── PertCore/           # Core LLM service and configuration logic
├── PertCLI/           # Command-line interface
└── PertGUI/           # SwiftUI graphical interface
```

### Core Components

- **LLMConfig**: Configuration structure for API endpoints
- **LLMService**: Main service for model detection, selection, and prompt conditioning
- **Prompt Conditioning**: System instruction that optimizes user prompts for expert-level responses

## Dependencies

- **Swift Argument Parser**: CLI argument parsing
- **SwiftUI**: GUI framework (for PertGUI)
- **Foundation**: Core iOS/macOS functionality

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with both CLI and GUI versions
5. Submit a pull request

## License

[Add your license information here]

## Troubleshooting

### Common Issues

1. **No local service detected**: Ensure LMStudio or Ollama is running locally
2. **Build failures**: Check that you have Swift 5.9+ and macOS 14.0+
3. **GUI won't launch**: Make sure you have the necessary development certificates installed

### Debug Mode

For debugging, you can modify the print statements in the source code to see detailed information about service detection and model selection.