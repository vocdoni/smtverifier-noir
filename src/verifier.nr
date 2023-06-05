use crate::helpers;
use dep::std;

fn verify(root : Field, key : Field, value : Field, siblings : [Field]) {
    verifyExtended(1, root, 0, 0, 0, key, value, 0, siblings);
}

fn verifyExtended<N>(enabled : Field, root : Field, oldKey : Field, oldValue : Field, 
    isOld0 : Field, key : Field, value : Field, fnc : Field, siblings : [Field; N]) {
    let nLevels = siblings.len() as Field;
    // Steps:
	//   1. Get the hash of both key-value pairsold and new one.
	//   2. Get the binary representation of the key new.
	//   3. Get the path of the current key.
	//   4. Calculate the root with the siblings provided.
	//   5. Compare the calculated root with the provided one.
	let hash1Old = helpers::endLeafValue(oldKey, oldValue);
	let hash1New = helpers::endLeafValue(key, value);

    let n2bNew = key.to_le_bits(254); // REVIEW: Fixed bit len

    let levIns = levelIns(siblings, if enabled == 1 { true } else { false });

    let mut stTops : [Field; N] = [0; N];
    let mut stIolds : [Field; N] = [0; N];
    let mut stI0s : [Field; N] = [0; N];
    let mut stInews : [Field; N] = [0; N];
    let mut stNas : [Field; N] = [0; N];
	for i in 0..nLevels {
        let (stTop, stInew, stIold, stI0, stNa) = if i == 0 {
            smVerifier(isOld0, levIns[0], fnc, enabled, 0, 0, 0, 1 - enabled)
        } else {
            smVerifier(isOld0, levIns[i], fnc, stTops[i-1], stI0s[i-1], 
                stIolds[i-1], stInews[i-1], stNas[i-1])
        };
        stTops[i] = stTop;
        stInews[i] = stInew;
        stIolds[i] = stIold;
        stI0s[i] = stI0;
        stNas[i] = stNa;
	}

    assert(stNas[nLevels-1] + stIolds[nLevels-1] + stInews[nLevels-1] + 
        stI0s[nLevels-1] == 1);

    let mut levels : [Field; N] = [0; N];
    let mut i = nLevels-1;
    for n in 0..nLevels {
        levels[i] = levelVerifier(stTops[i], stInews[i], stIolds[i], siblings[i],
            hash1Old, hash1New, n2bNew[i] as u1, if n != 0 { levels[i+1] } else { 0 });
        i -= 1;
    }

    let areKeyEquals = if oldKey == key { 1 } else { 0 };
	assert(helpers::multiAnd([fnc, 1 - isOld0, areKeyEquals, enabled]) == 0);
    assert(root == levels[0]);
}

fn levelIns<N>(siblings : [Field; N], enabled : bool) -> [Field; N] {
    if enabled {
        assert(siblings[siblings.len()-1] == 0);
    }

    let isZero = siblings.map(|i| if i == 0 { 1 } else { 0 });
    let mut isDone : [Field; N] = [0; N];
    let mut levIns : [Field; N] = [0; N];
    
    let last = 1 - isZero[siblings.len()-2];
    levIns[siblings.len()-1] = last;
    isDone[siblings.len()-2] = last;

    for n in 2..siblings.len() {
        let i = siblings.len()-n;
        levIns[i] = (1 - isDone[i]) * (1 - isZero[i-1]);
        isDone[i-1] = levIns[i] + isDone[i];
    }
    levIns[0] = 1 - isDone[0];
    levIns
}

fn smVerifier(is0 : Field, levIns : Field, fnc : Field, prevTop : Field, prevI0 : Field, 
    prevIold : Field, prevInew : Field, prevNa : Field) -> (Field, Field, Field, Field, Field) {
	let prevTopLevIns = prevTop * levIns;
	let prevTopLevInsFnc = prevTopLevIns * fnc;
	let stTop = prevTop - prevTopLevIns;
	let stInew = prevTopLevIns - prevTopLevInsFnc;
	let stIold = prevTopLevInsFnc * (1 - is0);
	let stI0 = prevTopLevIns * is0;
	let stNa = prevNa + prevInew + prevIold + prevI0;
    (stTop, stInew, stIold, stI0, stNa)
}

fn levelVerifier(stTop : Field, stInew : Field, stIold : Field, sibling : Field, 
    old1leaf : Field, new1leaf : Field, lrbit : u1, child : Field) -> Field {
    let (l, r) = helpers::switcher(lrbit, child, sibling);
    (helpers::intermediateLeafValue(l, r) * stTop) + (old1leaf * stIold) + 
        (new1leaf * stInew)
}

#[test]
fn test_verify() {
    let root = 21135506078746510573119705753579567335835726524098367527812922933644667691006;
    let key = 500400244448261235194511589700085192056257072811;
    let value = 10;
    let siblings : [Field; 8] = [
        13175438946403099127785287940793227584022396513432127658229341995655669945927,
		8906855681626013805208515602420790146700990181185755277830603493975762067087,
		9457781280074316365191154663065840032069867769247887694941521931147573919101,
		3886003602968045687040541715852317767887615077999207197223340281752527813105,
		5615297718669932502221460377065820025799135258753150375139282337562917282190,
		8028805327216345358010190706209509799652032446863364094962139617192615346584,
		572541247728029242828004565014369314635015057986897745288271497923406188177,
		9738042754594087795123752255236264962836518315799343893748681096434196901468,
    ];
    let mut totalSiblings : [Field; 160] = [0; 160];
    for i in 0..siblings.len() {
        totalSiblings[i] = siblings[i];
    }
    verify(root, key, value, totalSiblings);
}

#[test]
fn test_levelIns() {
    let siblings: [Field; 10] = [ 10, 4, 3, 2, 1, 0, 0, 0, 0, 0 ];
    let res = levelIns(siblings, true);
    assert(res[0] == 0);
    assert(res[1] == 0);
    assert(res[2] == 0);
    assert(res[3] == 0);
    assert(res[4] == 0);
    assert(res[5] == 1);
    assert(res[6] == 0);
    assert(res[7] == 0);
    assert(res[8] == 0);
    assert(res[9] == 0);
}

#[test]
fn test_smVerifier() {
    let (stTop, stInew, stIold, stI0, stNa) = smVerifier(1, 1, 1, 1, 1, 1, 1, 1);
    assert(stTop == 0);
    assert(stInew == 0);
    assert(stIold == 0);
    assert(stI0 == 1);
    assert(stNa == 4);
}

#[test]
fn test_levelVerifier() {
    let res = 7853200120776062878684798364095072458815029376092732009249414926327459813532;
    assert(levelVerifier(1, 1, 1, 2, 1, 1, 0, 1) == res);
}