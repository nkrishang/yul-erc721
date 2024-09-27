# ERC-721 YUL implementation

`src/ERC721Yul.sol` is an ERC-721 smart contract implemented almost entire inline assembly. It uses a straightforward storage layout and is gas competitive with optimized ERC-721 implementations such as solady and solmate.

`src/ERC721.yul` is a pure YUL implementation of the same, and is also tested and benchmarked using forge.

## Benchmarks

The benchmark file is the `test/Benchmark.t.sol` forge test file. Actual blockchain transactions may yield different results.

| Test              | YUL    | Inline Assembly | SOLADY | SOLMATE |
| ----------------- | ------ | --------------- | ------ | ------- |
| approve           | 31730  | 32299           | 32442  | 32458   |
| balanceOf         | 7534   | 7760            | 7797   | 7899    |
| burn              | 11636  | 11553           | 12152  | 11969   |
| mint              | 34798  | 35206           | 35293  | 35565   |
| ownerOf           | 7588   | 7657            | 7792   | 7801    |
| safeMint          | 106623 | 106899          | 107321 | 108844  |
| safeTransferFrom  | 111889 | 113786          | 113847 | 116468  |
| setApprovalForAll | 29437  | 29974           | 29992  | 30124   |
| transferFrom      | 37215  | 38202           | 38196  | 38695   |

If you know how to improve on this implementation, please make a PR. I'd love to learn.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

## Benchmark

```
$ make benchmark
```
