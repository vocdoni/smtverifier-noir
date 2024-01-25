package main

import (
	"math/big"
	"os"

	"github.com/consensys/gnark-crypto/ecc/bn254/twistededwards"
	"github.com/iden3/go-iden3-crypto/poseidon"
	toml "github.com/pelletier/go-toml/v2"
	"go.vocdoni.io/dvote/db"
	"go.vocdoni.io/dvote/db/pebbledb"
	"go.vocdoni.io/dvote/tree/arbo"
	"go.vocdoni.io/dvote/util"
)

type NoirInputs struct {
	Root *big.Int `toml:"root"`
	Key  *big.Int `toml:"key"`
	Value *big.Int `toml:"value"`
	Siblings         []*big.Int `toml:"siblings"`
}

const DefaultZkAddressLen = 20

type ZkAddress struct {
	Private *big.Int
	Public  *big.Int
	Scalar  *big.Int
}

func (zkAddr *ZkAddress) ArboBytes() []byte {
	bScalar := zkAddr.Scalar.Bytes()
	// swap endianess
	for i, j := 0, len(bScalar)-1; i < j; i, j = i+1, j-1 {
		bScalar[i], bScalar[j] = bScalar[j], bScalar[i]
	}
	// truncate to default length and return
	res := make([]byte, DefaultZkAddressLen)
	copy(res[:], bScalar)
	return res[:]
}

func FromBytes(seed []byte) (*ZkAddress, error) {
	// Setup the curve
	c := twistededwards.GetEdwardsCurve()
	// Get scalar private key hashing the seed with Poseidon hash
	private, err := poseidon.HashBytes(seed)
	if err != nil {
		return nil, err
	}
	// Get the point of the curve that represents the public key multipliying
	// the private key scalar by the base of the curve
	point := new(twistededwards.PointAffine).ScalarMultiplication(&c.Base, private)
	// Get the single scalar that represents the publick key hashing X, Y point
	// coordenates with Poseidon hash
	bX, bY := new(big.Int), new(big.Int)
	bX = point.X.BigInt(bX)
	bY = point.Y.BigInt(bY)
	public, err := poseidon.Hash([]*big.Int{bX, bY})
	if err != nil {
		return nil, err
	}

	// truncate the most significant n bytes of the public key (little endian)
	// where n is the default ZkAddress length
	publicBytes := public.Bytes()
	m := len(publicBytes) - DefaultZkAddressLen
	scalar := new(big.Int).SetBytes(publicBytes[m:])
	return &ZkAddress{private, public, scalar}, nil
}

func RandAddress() (*ZkAddress, error) {
	return FromBytes(util.RandomBytes(32))
}

func main() {
	database, err := pebbledb.New(db.Options{Path: os.TempDir()})
	if err != nil {
		panic(err)
	}
	arboTree, err := arbo.NewTree(arbo.Config{
		Database:     database,
		MaxLevels:    160,
		HashFunction: arbo.HashFunctionPoseidon,
	})
	if err != nil {
		panic(err)
	}

	weight := big.NewInt(10)
	candidate, err := RandAddress()
	if err != nil {
		panic(err)
	}
	err = arboTree.Add(candidate.ArboBytes(), arbo.BigIntToBytes(arbo.HashFunctionPoseidon.Len(), weight))
	if err != nil {
		panic(err)
	}

	for i := 0; i < 100; i++ {
		k, err := RandAddress()
		if err != nil {
			panic(err)
		}
		err = arboTree.Add(k.ArboBytes(), arbo.BigIntToBytes(arbo.HashFunctionPoseidon.Len(), weight))
		if err != nil {
			panic(err)
		}
	}

	_, _, pSiblings, _, err := arboTree.GenProof(candidate.ArboBytes())
	if err != nil {
		panic(err)
	}
	uSiblings, err := arbo.UnpackSiblings(arbo.HashFunctionPoseidon, pSiblings)
	if err != nil {
		panic(err)
	}

	siblings := []*big.Int{}
	for i := 0; i < 160; i++ {
		if i < len(uSiblings) {
			siblings = append(siblings, arbo.BytesToBigInt(uSiblings[i]))
		} else {
			siblings = append(siblings, big.NewInt(0))
		}
	}

	root, err := arboTree.Root()
	if err != nil {
		panic(err)
	}

	inputs := NoirInputs{
		Root:     arbo.BytesToBigInt(root),
		Key:      candidate.Scalar,
		Value:    weight,
		Siblings: siblings,
	}

	encInputs, err := toml.Marshal(inputs)
	if err != nil {
		panic(err)
	}
	if err := os.WriteFile("../../example/Prover.toml", encInputs, 0644); err != nil {
		panic(err)
	}
}
