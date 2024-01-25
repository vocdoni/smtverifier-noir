# smtverifier-noir

Port of [Circom Sparse Merkle Tree verifier](https://github.com/iden3/circomlib/blob/master/circuits/smt/smtverifier.circom) to Noir (v0.22.0 or later).

Compatible with [Vocdoni's Go implementation (Arbo by @arnaucube)](https://github.com/vocdoni/vocdoni-node/tree/main/tree/arbo).

## Example

An example program is provided under `example`. To run it:

* Generate inputs with `scripts/generate_inputs`:
    ```bash
    cd scripts/generate_inputs && go mod tidy && go run main.go
    ```

* Generate a proof:
    ```bash
    cd ../.. && nargo prove --package smtverifier_example
    ```
	
* Verify it:
    ```bash
    nargo verify --package smtverifier_example
    ```
	
---

DISCLAIMER: This repository provides proof-of-concept implementations. These implementations are for demonstration purposes only. These circuits are not audited, and this is not intended to be used as a library for production-grade applications.
