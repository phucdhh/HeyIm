# Contributing to HeyIm

Thank you for your interest in contributing to HeyIm! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to learn and improve the project together.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:

1. **Clear title** describing the problem
2. **Steps to reproduce** the bug
3. **Expected behavior** vs actual behavior
4. **Environment details**:
   - macOS version
   - Hardware (Mac Mini, MacBook, etc.)
   - RAM size
   - Model version being used
5. **Relevant logs** or error messages

### Suggesting Features

Feature requests are welcome! Please:

1. Check if the feature has already been requested
2. Describe the use case clearly
3. Explain how it would benefit users
4. Consider implementation complexity

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation if needed

4. **Test your changes**:
   ```bash
   # Backend
   cd backend && swift test
   
   # Frontend
   cd frontend && npm test
   ```

5. **Commit with clear messages**:
   ```bash
   git commit -m "feat: add xyz feature"
   git commit -m "fix: resolve abc issue"
   ```

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request** with:
   - Clear description of changes
   - Reference to related issues
   - Screenshots if UI changes

## Development Setup

### Backend (Swift)

```bash
cd backend
swift build
.build/debug/HeyImServer
```

### Frontend (Next.js)

```bash
cd frontend
npm install
npm run dev
```

## Code Style

### Swift

- Use Swift naming conventions
- Add documentation comments for public APIs
- Keep functions focused and small
- Use meaningful variable names

```swift
/// Generates an image from the given prompt
/// - Parameters:
///   - prompt: Text description of desired image
///   - steps: Number of diffusion steps
/// - Returns: Generated CGImage
public func generateImage(prompt: String, steps: Int) throws -> CGImage {
    // Implementation
}
```

### TypeScript/React

- Use TypeScript for type safety
- Follow React best practices
- Use functional components
- Add PropTypes or interfaces

```typescript
interface GenerateFormProps {
  onSubmit: (request: GenerateRequest) => void;
  isLoading: boolean;
}

export function GenerateForm({ onSubmit, isLoading }: GenerateFormProps) {
  // Implementation
}
```

## Testing

### Backend Tests

```bash
cd backend
swift test
```

### Frontend Tests

```bash
cd frontend
npm test
npm run test:e2e
```

### Manual Testing

Before submitting a PR, test:

1. Text-to-image generation
2. Image-to-image with different strength values
3. Error handling (invalid inputs)
4. Performance (check generation time)

## Documentation

Update documentation when:

- Adding new features
- Changing APIs
- Modifying configuration
- Adding dependencies

Documentation files:
- `README.md` - Main Vietnamese documentation
- `README.en.md` - English documentation
- `docs/` - Detailed guides

## Performance Considerations

When contributing, consider:

- **ANE Optimization**: Keep models compatible with Neural Engine
- **Memory Usage**: Monitor RAM consumption
- **Generation Speed**: Profile performance impact
- **Model Size**: Avoid unnecessary model size increases

## Questions?

Feel free to:
- Open a discussion on GitHub
- Comment on existing issues
- Ask in pull requests

We're here to help!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
