# smtverifier-noir

Port of [Circom Sparse Merkle Tree verifier](https://github.com/iden3/circomlib/blob/master/circuits/smt/smtverifier.circom) to Noir (v0.22.0 or later).

Compatible with [Vocdoni's Go implementation (Arbo by @arnaucube)](https://github.com/vocdoni/vocdoni-node/tree/main/tree/arbo).

## Example

Requires Nargo: 
> nargo 0.22.0 (git version hash: 4b16090beecd0fcdd41c9e7b8f615c4625c26a5b, is dirty: false)


Noir example source code *example/src/main.nr*:

```rust
use dep::smt;

fn main(root : pub Field, key : Field, value : Field, siblings : [Field; 160]) {
    smt::verifier::verify(root, key, value, siblings);
}
```

* Generate inputs with `scripts/generate_inputs`
    ```bash
    cd scripts/generate_inputs && go mod tidy && go run main.go
    ```

* Check the circuit:
    ```bash
    nargo check
    ```
---

DISCLAIMER: This repository provides proof-of-concept implementations. These implementations are for demonstration purposes only. These circuits are not audited, and this is not intended to be used as a library for production-grade applications.
