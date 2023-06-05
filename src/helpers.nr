use dep::std;

// endLeafValue returns the encoded childless leaf value for the key-value pair
// providedhashing it with the predefined hashing function 'H':
//
//	newLeafValue = H(key | value | 1)
fn endLeafValue(k : Field, v : Field) -> Field {
    std::hash::poseidon::bn254::hash_3([k, v, 1])
}

// intermediateLeafValue returns the encoded intermediate leaf value for the
// key-value pair providedhashing it with the predefined hashing function 'H':
//
//	intermediateLeafValue = H(l | r)
fn intermediateLeafValue(l : Field, r : Field) -> Field {
	std::hash::poseidon::bn254::hash_2([l, r])
}

fn switcher(sel : u1, l : Field, r : Field) -> (Field, Field) {
    if sel == 0 {
        (l, r)
    } else {
        (r, l)
    }
}

fn multiAnd<N>(arr : [Field; N]) -> Field {
    arr.reduce(|a, b| a & b)
}

#[test]
fn test_endLeafValue() {
    assert(endLeafValue(1, 2) == 13578938674299138072471463694055224830892726234048532520316387704878000008795);
}

#[test]
fn test_intermediateLeafValue() {
    assert(intermediateLeafValue(1, 2) == 7853200120776062878684798364095072458815029376092732009249414926327459813530);
}

#[test]
fn test_switcher() {
    let (l1, r1) = switcher(1, 2, 3);
    assert(l1 == 3);
    assert(r1 == 2);

    let (l0, r0) = switcher(0, 2, 3);
    assert(l0 == 2);
    assert(r0 == 3);
}

#[test]
fn test_multiAnd() {
    assert(multiAnd([1]) == 1);
    assert(multiAnd([0]) == 0);
    assert(multiAnd([1, 1, 0, 0]) == 0);
    assert(multiAnd([1, 1, 1, 1]) == 1);
    assert(multiAnd([0, 0, 0, 0]) == 0);
}