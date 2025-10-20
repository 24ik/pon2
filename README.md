# Pon! Tsu

Pon! Tsu is an application and library of [Puyo Puyo](https://puyo.sega.jp/)
and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).

Features:
- Solve Nazo Puyos.
- Generate Nazo Puyos.
- Permute pairs in Nazo Puyos to find unique-solution problems.
- [Edit Nazo Puyos](https://24ik.github.io/pon2/stable/ide/?mode=ee&field=t-&steps&goal=0_0_).
- [Play a marathon mode](https://24ik.github.io/pon2/stable/marathon/).

## Installation

### Downloading Built Binary

The built binary is available at the
[latest release](https://github.com/24ik/pon2/releases/latest).

### Manual Installation

```shell
nimble install pon2 -p:-d:danger
```

The list of compile options is available in the
[API documentation](https://24ik.github.io/pon2/stable/docs/api/).

## Usage

### CLI or Native Application

See the usage by running `pon2`.

### Web Application

See the documentations:

- [Simulator](https://24ik.github.io/pon2/stable/docs/simulator/)

## For Developers

### API Usage

See the [API documentation](https://24ik.github.io/pon2/stable/docs/api/).

### Running Tests

```shell
nimble test
```

### Generating Web Pages

Run `nimble web` to generate files in the `www` directory.

### Contribution

Please work on a new branch and then submit a PR for the `main` branch.

## License

Apache-2.0

See [LICENSE](./LICENSE) and [NOTICE](./NOTICE) for details.
