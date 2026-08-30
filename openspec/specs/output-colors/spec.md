# Output Colors

## Purpose

ANSI color system for all wt command output — color definitions, NO_COLOR support, and per-command colorization.

## Requirements

### Requirement: Color Definitions
The system SHALL define ANSI color variables at script initialization for use in all output formatting. Color variables SHALL use standard 8-color palette (red, green, yellow, blue, cyan, magenta, white) plus bold and dim attributes.

#### Scenario: Color variables available
- **WHEN** script loads
- **THEN** color variables are defined for: reset, bold, dim, red, green, yellow, cyan

#### Scenario: Color variables are empty strings when NO_COLOR set
- **WHEN** `NO_COLOR` environment variable is set (any value)
- **THEN** all color variables SHALL be set to empty string

### Requirement: NO_COLOR Support
The system SHALL respect the `NO_COLOR` environment variable convention (https://no-color.org/).

#### Scenario: NO_COLOR disables all colors
- **WHEN** `NO_COLOR` is set in environment
- **THEN** all wt output SHALL contain no ANSI escape sequences
- **THEN** output SHALL be identical to uncolored output

#### Scenario: NO_COLOR unset enables colors
- **WHEN** `NO_COLOR` is not set
- **THEN** wt SHALL use ANSI color codes in output

### Requirement: Stdout Never Colored
The system SHALL NOT add color codes to stdout output.

#### Scenario: Path output on stdout
- **WHEN** a command prints a directory path to stdout (for shell integration)
- **THEN** the path SHALL contain no ANSI escape sequences
- **THEN** shell cd wrapper can resolve the path without stripping color codes

### Requirement: Error Messages Colored Red
The system SHALL display error messages (via `die`) in red.

#### Scenario: Error output
- **WHEN** `die` is called with an error message
- **THEN** the error prefix and message SHALL be rendered in red
