# Final Year Project | Glorious Deliverance Agency 1

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Godot Engine](https://img.shields.io/badge/Godot-4.5-blue.svg)](https://godotengine.org/)

![Home Screen](1.Codebase/src/assets/home.png)

This is my Final Year Project (FYP) exploring an **AI-Powered Dynamic Narrative System for RPGs**. The project investigates how Large Language Models (LLMs) can be effectively constrained to produce coherent, thematically consistent narratives in real-time gaming experiences.

**Department of Informatics, University of Sussex**

## The Game

An AI-native 2D RPG where you play a reluctant hero in a dysfunctional team whose attempts to save the world with "positive energy" only accelerate its destruction. The game implements a unique *Reality vs. Positive Energy" thematic framework as a dark satirical critique of toxic positivity and hustle culture.

Built with Godot 4.5 and typed GDScript, this repository contains the complete project including source code, Report and Video.

# Running the Project

1. Clone the repository:

    ```bash
    git clone https://github.com/dundd2/Individual-Project.git
    cd Individual-Project
    ```

2. **Option A - Using Godot Editor:**
   - Open the Godot Engine
   - Click "Import" and select the `project.godot` file from the root
   - Run the project from the editor

3. **Option B - Using Command Line:**

   ```bash
   # Launch the game
   godot4 --path .
   
   # Open in editor mode
   godot4 --path . --editor
   
   # Run all unit tests
   godot4 --headless --path . --run "res://1.Codebase/src/scenes/tests/all_tests_runner.tscn"
   ```

The main entry point is `1.Codebase/menu_main.tscn`.

# Project Structure

```
Individual-Project/
├── .github/
│   └── workflows/           # CI/CD workflows (build, deploy, release)
├── 1.Codebase/              # Main source code directory
│   ├── src/
│   │   ├── scripts/
│   │   │   ├── core/        # Core autoload systems
│   │   │   │   ├── ai/      # AI provider implementations
│   │   │   │   ├── game_state.gd           # Central state management
│   │   │   │   ├── ai_manager.gd           # AI narrative generation
│   │   │   │   ├── audio_manager.gd        # Sound and music
│   │   │   │   ├── asset_registry.gd       # Asset cataloging
│   │   │   │   ├── achievement_system.gd   # Player achievements
│   │   │   │   ├── event_bus.gd            # Event system
│   │   │   │   ├── service_locator.gd      # Service registry
│   │   │   │   └── ...                     # Other core systems
│   │   │   ├── ui/          # UI controllers and components
│   │   │   ├── game/        # Game logic scripts
│   │   │   └── tests/       # Test helper scripts
│   │   ├── scenes/
│   │   │   ├── ui/          # UI scene files
│   │   │   └── tests/       # Test runner scenes
│   │   └── assets/          # Art, audio, fonts, textures
│   ├── Unit Test/           # Comprehensive unit test suite
│   ├── localization/        # Translation files (EN, ZH)
│   ├── menu_main.tscn       # Main menu entry point
│   └── main.tscn            # Bootstrap scene
├── 2.Report/                # Project documentation and reports
├── 3.Video/                 # Demo videos and recordings
├── 4.Pre-Built V1.0/        # Pre-compiled game binaries
├── LICENSE.md               # MIT License
├── project.godot            # Godot project configuration
└── export_presets.cfg       # Export settings for all platforms
```

# Testing

Run the comprehensive test suite locally:

```bash
godot4 --headless --path . --run "res://1.Codebase/src/scenes/tests/all_tests_runner.tscn"
```

# Build & Deployment

The project uses GitHub Actions for automated building and deployment.

- **Manual Trigger**: The `Build and Deploy Game` workflow is triggered manually via the `workflow_dispatch` event in the Actions tab.
- **Platforms**: Builds are generated for:
  - Web (HTML5)
  - Windows Desktop
  - Linux (x86_64)
  - Linux ARM64
- **Releases**: A GitHub Release is automatically created with zipped artifacts for each platform.
- **Web Deployment**: The Web build is automatically deployed to the `gh-pages` branch.
- **API Keys**: For the Web build, the `GEMINI_API_KEY` secret is injected into the build if provided in the repository secrets.

# License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
