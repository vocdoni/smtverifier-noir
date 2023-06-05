# smtverifier-noir

Port of [Circom Sparse Merkle Tree verifier](https://github.com/iden3/circomlib/blob/master/circuits/smt/smtverifier.circom) to Noir (v0.6.0).


## Example

Requires Nargo: 
> nargo 0.6.0 (git version hash: 7bad243f2da93337afdddd832dd6467c8c8ddfb2, is dirty: false)


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