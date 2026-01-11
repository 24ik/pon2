# Pon! Tsu

Pon! Tsu is an application and library dedicated to [Puyo Puyo](https://puyo.sega.jp/)
and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).

## Features

- **Solve** Nazo Puyo puzzles.
- **Generate** new Nazo Puyo puzzles.
- **Permute** pairs in Nazo Puyo to find problems with unique solutions.
- **[Edit Nazo Puyo](https://24ik.github.io/pon2/stable/studio/)** via the web interface.
- **[Play Marathon](https://24ik.github.io/pon2/stable/marathon/)** in your browser.
- **[Nazo Puyo Grimoire](https://24ik.github.io/pon2/stable/grimoire/)**.

## Installation

### Download Pre-built Binaries

You can download the latest pre-built binaries from the
[Releases page](https://github.com/24ik/pon2/releases/latest).

### Manual Installation

To install via [Nimble](https://nim-lang.github.io/nimble/), run:

```shell
nimble install pon2 -p:-d:danger
```

A full list of compilation options is available in the
[API documentation](https://24ik.github.io/pon2/stable/docs/api/).

## Usage

Run `pon2` in your terminal to see the available commands and usage instructions.

## For Developers

### API Reference

Detailed documentation is available here:
[API documentation](https://24ik.github.io/pon2/stable/docs/api/).

### Running Tests

To run the full test, run:

```shell
nimble test
```

### Benchmarking

To measure performance, run:

```shell
nim c -r benchmarks/main.nim
```

### Generating Web Pages

To generate files in the `pages` directory, run:

```shell
nimble pages
```

### Contributing

1. Create a new branch for your feature or bug fix.
1. Submit a Pull Request (PR) to the `main` branch.

## License

Pon! Tsu is licensed under either of

* Apache License, Version 2.0
* MIT License

at your option.
See [LICENSE-APACHE](./LICENSE-APACHE), [LICENSE-MIT](./LICENSE-MIT),
and [NOTICE](./NOTICE) for more details.
