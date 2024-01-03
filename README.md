# Pon! Tsu

Pon! Tsu is an application and library for [Puyo Puyo](https://puyo.sega.jp/)
and [Nazo Puyo](https://vc.sega.jp/3ds/nazopuyo/).

Features:
- Solver: Solves the Nazo Puyo.
- Generator: Generates the Nazo Puyo.
- Permuter: Permutes the pairs in the Nazo Puyo to find a unique-solution
problem.
- Editor+Simulator: Edits and Plays the Puyo Puyo and Nazo Puyo.

Not supported now:
- Wall cell
- Hard-garbage puyo
- Iron puyo
- Fever rule
- Dropping garbage

## Installation

### Downloading Binary

You can get the binary at the
[latest release](https://github.com/izumiya-keisuke/pon2/releases/latest).

**NOTE:** Built binary may not work on macOS due to the limitation of
[NiGui](https://github.com/simonkrauter/NiGui).

### Manual Installation

```shell
nimble install https://github.com/izumiya-keisuke/pon2 -p:-d:danger -p:-d:avx2=<bool> -p:-d:bmi2=<bool>
```

## Usage

See the documentations:
- [Solver](./docs/solve.md)
- [Generator](./docs/generate.md)
- [Permuter](./docs/permute.md)
- [Editor+Simulator](./docs/edit.md)

## For Developers

### API Usage

See the [API documentation](https://izumiya-keisuke.github.io/pon2/pon2.html).

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

> Copyright 2023 Keisuke Izumiya
>
> Licensed under the Apache License, Version 2.0 (the "License");
> you may not use this file except in compliance with the License.
> You may obtain a copy of the License at
>
>     http://www.apache.org/licenses/LICENSE-2.0
>
> Unless required by applicable law or agreed to in writing, software
> distributed under the License is distributed on an "AS IS" BASIS,
> WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
> See the License for the specific language governing permissions and
> limitations under the License.
