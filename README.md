# ERC-721 YUL implementation

`src/ERC721Yul.sol` is an ERC-721 smart contract implemented almost entire using Yul / inline assembly. It uses a straightforward storage layout and is gas competitive with optimized ERC-721 implementation such as solady and solmate.

## Benchmarks

The benchmark file is the `test/Benchmark.t.sol` forge test file. Actual blockchain transactions may yield different results.

| Test              | YUL    | SOLADY | SOLMATE (mod) |
| ----------------- | ------ | ------ | ------------- |
| approve           | 32264  | 32377  | 32480         |
| balanceOf         | 7788   | 7841   | 7854          |
| burn              | 11580  | 12116  | 11969         |
| mint              | 35235  | 35248  | 35565         |
| ownerOf           | 7709   | 7858   | 7756          |
| safeMint          | 106866 | 107233 | 108865        |
| safeTransferFrom  | 113840 | 113824 | 116383        |
| setApprovalForAll | 30048  | 30014  | 30146         |
| transferFrom      | 38209  | 38173  | 38739         |

If you know how to improve on thsi implementation, please make a PR. I'd love to learn.

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
