# Pon! Tsu

Pon! Tsu is an application and library for [Puyo Puyo](https://puyo.sega.jp/)
and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).

Features:
- Solver: Solves the Nazo Puyo.
- Generator: Generates the Nazo Puyo.
- Permuter: Permutes the pairs in the Nazo Puyo to find a unique-solution
problem.
- [GUI Application](https://24ik.github.io/pon2/?kind=n&mode=e&field=t-&pairs&req-kind=0&req-color=0): GUI simulator for Puyo Puyo and Nazo Puyo.
- [Marathon](https://24ik.github.io/pon2/marathon/): Search for pairs sequence and play a marathon mode.

Not supported now:
- Wall Puyo, Hard-garbage Puyo, and Iron Puyo
- Dropping garbage puyo
- Puyo Puyo Fever

Note that now I am working hard on CUI and web-GUI development, and the
native-GUI application is beta version.

## Installation

### Downloading Binary

You can get the binary at the
[latest release](https://github.com/24ik/pon2/releases/latest).
Note that the built binary may not work on macOS due to the limitation of
[NiGui](https://github.com/simonkrauter/NiGui).

### Manual Installation

```shell
nimble install pon2 -p:-d:danger
```

If you want to specify the instruction set, use the following command:

```shell
nimble install pon2 -p:-d:danger -p:-d:pon2.avx2=<bool> -p:-d:pon2.bmi2=<bool>
```

## Usage

See the documentations:
- [Solver](./docs/solve.md)
- [Generator](./docs/generate.md)
- [Permuter](./docs/permute.md)
- [GUI Application](./docs/gui.md)

## For Developers

### Known Issues

- On Windows, the followings does not work:
    - cpp and JS backend
    - AVX2

### API Usage

See the [API documentation](https://24ik.github.io/pon2/docs/pon2.html).

### Running Tests

```shell
nimble test
```

### Writing Tests

1. Create a new directory directly under the `tests` directory.
1. Create a new file `main.nim` in the directory.
1. Write the entry point of the test as `main()` procedure in the file.

### Generating Web Page

Run the following command to generate files in the `www` directory.

```shell
nimble web
```

### Contribution

Please work on a new branch and then submit a PR for the `main` branch.

## License

Apache-2.0
