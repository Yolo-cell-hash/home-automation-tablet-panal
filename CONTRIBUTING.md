# Contributing to Home Automation Tablet Panel

Thank you for your interest in contributing to the Home Automation Tablet Panel project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

Please be respectful and constructive in all interactions. We are committed to providing a welcoming and inclusive environment for all contributors.

## Getting Started

### Prerequisites

1. **Flutter SDK** (^3.9.0 or later)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (comes with Flutter)

3. **IDE Setup**
   - VS Code with Flutter extension (recommended)
   - Android Studio with Flutter plugin
   - IntelliJ IDEA with Flutter plugin

### Setting Up Your Development Environment

1. **Fork the repository**
   
   Click the "Fork" button on the GitHub repository page.

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/home-automation-tablet-panal.git
   cd home-automation-tablet-panal
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/Yolo-cell-hash/home-automation-tablet-panal.git
   ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Development Workflow

### Creating a Feature Branch

1. **Sync with upstream**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create a new branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

   Branch naming conventions:
   - `feature/` - New features
   - `bugfix/` - Bug fixes
   - `hotfix/` - Critical fixes
   - `docs/` - Documentation changes
   - `refactor/` - Code refactoring

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/widget_test.dart
```

### Code Analysis

```bash
# Run static analysis
flutter analyze

# Fix formatting issues
dart format lib/ test/
```

## Coding Standards

### Dart/Flutter Style Guide

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and [Flutter Style Guide](https://docs.flutter.dev/development/tools/formatting).

### Code Formatting

- Use `dart format` before committing
- Maximum line length: 80 characters
- Use trailing commas for better diffs

### Widget Guidelines

1. **Stateless vs Stateful**
   - Use `StatelessWidget` when the widget doesn't need to manage state
   - Use `StatefulWidget` only when local state is required

2. **Widget Organization**
   ```dart
   class MyWidget extends StatelessWidget {
     // 1. Constructor
     const MyWidget({super.key, required this.title});
     
     // 2. Properties
     final String title;
     
     // 3. Build method
     @override
     Widget build(BuildContext context) {
       return Container();
     }
     
     // 4. Helper methods
     Widget _buildHeader() {
       return Text(title);
     }
   }
   ```

3. **Extract Reusable Widgets**
   - Create reusable widgets in `lib/widgets/`
   - Keep widgets focused on a single responsibility

### State Management

This project uses Provider for state management. Follow these patterns:

```dart
// Reading state
final appState = Provider.of<AppState>(context, listen: true);

// Updating state
final appState = Provider.of<AppState>(context, listen: false);
appState.someMethod();
```

### File Organization

```
lib/
├── main.dart              # Entry point only
├── screens/               # Full-page screens
├── widgets/               # Reusable UI components
├── utils/                 # Utility classes and helpers
├── models/                # Data models (if needed)
└── services/              # API and service classes (if needed)
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `home_screen.dart` |
| Classes | PascalCase | `HomeScreen` |
| Variables | camelCase | `isConnected` |
| Constants | camelCase or SCREAMING_SNAKE_CASE | `maxRetries` |
| Private members | _camelCase | `_isLoading` |

### Comments and Documentation

```dart
/// A widget that displays sensor information.
/// 
/// The [SensorCard] shows the sensor status and allows
/// configuration through a dialog.
/// 
/// Example:
/// ```dart
/// SensorCard(
///   title: 'Fire Sensor',
///   icon: 'images/fire.png',
/// )
/// ```
class SensorCard extends StatefulWidget {
  /// The title displayed on the card.
  final String title;
  
  /// The path to the icon asset.
  final String icon;
}
```

## Commit Guidelines

### Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

### Examples

```
feat(presets): add custom preset creation

fix(connection): resolve Firebase reconnection issue

docs(readme): update installation instructions

refactor(widgets): extract status bar into separate component
```

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass**
   ```bash
   flutter test
   ```

2. **Run code analysis**
   ```bash
   flutter analyze
   ```

3. **Format your code**
   ```bash
   dart format lib/ test/
   ```

4. **Update documentation** if needed

### Submitting a Pull Request

1. Push your branch to your fork
   ```bash
   git push origin feature/your-feature-name
   ```

2. Open a Pull Request on GitHub

3. Fill out the PR template with:
   - Description of changes
   - Related issue numbers
   - Screenshots (for UI changes)
   - Testing instructions

### PR Review Process

- PRs require at least one approval before merging
- Address all review comments
- Keep PRs focused and reasonably sized
- Squash commits if requested

## Reporting Issues

### Bug Reports

Include the following information:

1. **Description**: Clear description of the bug
2. **Steps to Reproduce**: Numbered steps to reproduce
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**:
   - Flutter version
   - Device/Emulator
   - OS version
6. **Screenshots/Logs**: If applicable

### Feature Requests

1. **Use Case**: Describe the problem you're trying to solve
2. **Proposed Solution**: Your suggested implementation
3. **Alternatives**: Other solutions you've considered
4. **Additional Context**: Any other relevant information

## Questions?

If you have questions about contributing, feel free to:

1. Open an issue with the `question` label
2. Review existing issues and PRs for context
3. Check the project documentation

Thank you for contributing! 🎉
