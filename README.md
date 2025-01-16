# Zig Origin (zo)

Zig Origin (zo) is a versatile command-line tool designed to streamline the initialization and management of Zig projects. It offers various templates and options to cater to different project types, including standard applications, minimal setups, embedded systems, and projects with Nix Flake integration.

## Features

- Initialize Zig projects with different templates:
  - Default: Standard Zig project setup
  - Minimal: Bare-bones Zig project structure
  - Embedded: Tailored for embedded systems development
  - Flake: Includes Nix Flake for Zig development environment
- Embedded systems support with MicroZig integration
- Optional version control system (VCS) initialization (Git, Mercurial, and Jujutsu)

## Usage

### Main Init Command
zo init [OPTIONS]

Initializes a `zig build` project in the current working directory.

#### Options:
- `-h, --help`: Print help and exit
- `-m, --minimal`: Initialize a minimal `zig build` project
- `-f, --flake`: Add a basic Nix Flake for creating a Zig dev environment
- `--e, --embedded`: Initialize an embedded project
- `--vcs <VCS>`: Initialize a repo for the specified VCS (git, hg, or jj)

### Embed Command
zo embed <COMMAND>

#### Subcommands:
- `init`: Initialize a basic embedded Zig project using MicroZig

#### Options:
- `-h, --help`: Print help and exit
- `--vcs <VCS>`: Initialize a repo for the specified VCS (git, hg, or jj)

## Examples

1. Create a default Zig project:
zo init
2. Set up a minimal project with Git:
zo init -m --vcs git
3. Initialize a project with Nix Flake support:
zo init -f
4. Set up an embedded project using MicroZig:
zo embed init
5. Initialize an embedded MicroZig project with Mercurial:
zo embed init --vcs hg

## Installation
The only option right now is from source.
1. Pull repo down
2. Run `zig build`
3. Move the executable to your $PATH

## Dependencies

- Zig compiler
- Git, Mercurial, or Jujutsu (optional, for VCS initialization)
- Nix (optional, for Flake support)
- MicroZig (for embedded projects)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
