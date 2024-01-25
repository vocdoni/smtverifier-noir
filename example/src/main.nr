use dep::smt;

fn main(root : pub Field, key : Field, value : Field, siblings : [Field; 160]) {
    smt::verifier::verify(root, key, value, siblings);
}
