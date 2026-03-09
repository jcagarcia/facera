# Contributing

Thank you for your interest in contributing to Facera!

---

## Getting Started

### 1. Fork and Clone

```bash
# Fork on GitHub
git clone https://github.com/YOUR_USERNAME/facera.git
cd facera
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Run Tests

```bash
bundle exec rspec
```

All tests should pass before you start.

---

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/amazing-feature
```

### 2. Make Changes

Edit code, add tests, update documentation.

### 3. Run Tests

```bash
bundle exec rspec
```

Ensure all tests pass and add new tests for your changes.

### 4. Commit

```bash
git add .
git commit -m 'Add amazing feature'
```

### 5. Push

```bash
git push origin feature/amazing-feature
```

### 6. Open Pull Request

Go to GitHub and open a Pull Request.

---

## Code Style

### Ruby Style Guide

Follow the [Ruby Style Guide](https://rubystyle.guide/):

- Use 2 spaces for indentation
- Maximum line length of 100 characters
- Use `snake_case` for methods and variables
- Use `CamelCase` for classes and modules
- Use `SCREAMING_SNAKE_CASE` for constants

### Examples

**Good:**
```ruby
def create_payment(amount:, currency:)
  Payment.create(
    amount: amount,
    currency: currency,
    status: :pending
  )
end
```

**Bad:**
```ruby
def createPayment(amount, currency)
  Payment.create(amount: amount, currency: currency, status: :pending)
end
```

---

## Testing

### Test Structure

```ruby
RSpec.describe Facera::Core do
  describe "#entity" do
    it "defines an entity" do
      core = Facera::Core.new(:test)
      core.entity(:payment) { }
      expect(core.entities).to have_key(:payment)
    end

    it "raises error for duplicate entity" do
      core = Facera::Core.new(:test)
      core.entity(:payment) { }
      expect {
        core.entity(:payment) { }
      }.to raise_error(Facera::DuplicateEntityError)
    end
  end
end
```

### Test Coverage

- Aim for >90% test coverage
- Test happy paths
- Test error cases
- Test edge cases

### Running Tests

```bash
# All tests
bundle exec rspec

# Specific file
bundle exec rspec spec/facera/core_spec.rb

# Specific test
bundle exec rspec spec/facera/core_spec.rb:10

# With coverage
COVERAGE=true bundle exec rspec
```

---

## Documentation

### Code Comments

Add comments for complex logic:

```ruby
# Validates state transition is allowed based on current status
# and target status. Returns true if transition is valid.
def valid_transition?(from_status, to_status)
  VALID_TRANSITIONS[from_status]&.include?(to_status)
end
```

### README Updates

Update README.md if you:
- Add new features
- Change public API
- Add configuration options

### Wiki Updates

Update wiki pages for:
- New concepts
- Architecture changes
- Best practices

---

## Pull Request Guidelines

### PR Title

Use clear, descriptive titles:

- ✅ "Add support for nested entities"
- ✅ "Fix capability validation bug"
- ❌ "Update code"
- ❌ "Fixes"

### PR Description

Include:
- What changed
- Why it changed
- How to test it
- Related issues

**Template:**
```markdown
## What

Brief description of changes.

## Why

Why these changes are needed.

## How to Test

1. Step 1
2. Step 2
3. Expected result

## Related Issues

Fixes #123
```

### PR Checklist

- [ ] Tests pass locally
- [ ] Added tests for new code
- [ ] Updated documentation
- [ ] Followed code style guidelines
- [ ] No breaking changes (or documented)
- [ ] Commit messages are clear

---

## Areas to Contribute

### 🐛 Bug Fixes

Found a bug? Great!

1. Check if issue already exists
2. Create issue with reproduction steps
3. Submit PR with fix and test

### ✨ New Features

Want to add a feature?

1. Open issue to discuss
2. Get feedback from maintainers
3. Implement with tests
4. Submit PR

### 📝 Documentation

Documentation always needs improvement:

- Fix typos
- Add examples
- Clarify confusing sections
- Add missing documentation

### 🧪 Tests

More tests are always welcome:

- Increase coverage
- Test edge cases
- Add integration tests
- Improve test readability

### 🚀 Performance

Performance improvements:

- Benchmark before/after
- Document improvement
- Ensure no breaking changes

---

## Code Review Process

### What We Look For

1. **Correctness** - Does it work?
2. **Tests** - Is it tested?
3. **Documentation** - Is it documented?
4. **Style** - Does it follow guidelines?
5. **Performance** - Is it efficient?

### Review Timeline

- Initial review: 1-3 days
- Follow-up: 1-2 days
- Merge: When approved

### Addressing Feedback

- Be responsive to comments
- Ask questions if unclear
- Make requested changes
- Re-request review when ready

---

## Development Setup

### Prerequisites

- Ruby 3.0+
- Bundler
- Git

### Local Development

```bash
# Clone
git clone https://github.com/yourusername/facera.git
cd facera

# Install
bundle install

# Run tests
bundle exec rspec

# Run examples
cd examples/server
rackup -p 9292

# Test endpoints
curl http://localhost:9292/api/v1/health
```

### Development Tools

**RSpec:**
```bash
bundle exec rspec --format documentation
```

**Rubocop (linting):**
```bash
bundle exec rubocop
```

**Guard (auto-testing):**
```bash
bundle exec guard
```

---

## Release Process

(For maintainers)

### 1. Update Version

```ruby
# lib/facera/version.rb
module Facera
  VERSION = "0.2.0"
end
```

### 2. Update Changelog

```markdown
# CHANGELOG.md

## [0.2.0] - 2026-03-09

### Added
- New feature X
- New feature Y

### Fixed
- Bug Z

### Changed
- Behavior W
```

### 3. Commit and Tag

```bash
git add .
git commit -m "Release v0.2.0"
git tag v0.2.0
git push origin main --tags
```

### 4. Build and Push Gem

```bash
gem build facera.gemspec
gem push facera-0.2.0.gem
```

---

## Communication

### GitHub Issues

Use issues for:
- Bug reports
- Feature requests
- Questions
- Discussions

### GitHub Discussions

Use discussions for:
- General questions
- Ideas
- Show and tell
- Community help

### Code of Conduct

Be respectful and inclusive:
- Welcome newcomers
- Be patient with questions
- Provide constructive feedback
- Assume good intentions

---

## Recognition

Contributors will be:
- Listed in README
- Mentioned in releases
- Thanked publicly

Thank you for contributing! 🎉

---

## Questions?

- Open an issue
- Start a discussion
- Email: your-email@example.com

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
