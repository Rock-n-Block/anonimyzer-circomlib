/*

SMTVerifier is a component to verify inclusion/exclusion of an element in the tree


fnc:  0 -> VERIFY INCLUSION
      1 -> VERIFY NOT INCLUSION

 */


include "../gates.circom";
include "../bitify.circom";
include "../comparators.circom";
include "../switcher.circom";
include "smtlevins.circom";
include "smtverifierlevel.circom";
include "smtverifiersm.circom";
include "smthash.circom";

template SMTVerifier(nLevels) {
    signal input root;
    signal input siblings[nLevels];
    signal input oldKey;
    signal input oldValue;
    signal input isOld0;
    signal input key;
    signal input value;
    signal input fnc;

    component hash1Old = SMTHash1();
    hash1Old.key <== oldKey;
    hash1Old.value <== oldValue;

    component hash1New = SMTHash1();
    hash1New.key <== key;
    hash1New.value <== value;

    component n2bOld = Num2Bits_strict();
    component n2bNew = Num2Bits_strict();

    n2bOld.in <== oldKey;
    n2bNew.in <== key;

    component smtLevIns = SMTLevIns(nLevels);
    for (var i=0; i<nLevels; i++) smtLevIns.siblings[i] <== siblings[i];
    smtLevIns.enabled <== 1;

    component sm[nLevels];
    for (var i=0; i<nLevels; i++) {
        sm[i] = SMTVerifierSM();
        if (i==0) {
            sm[i].prev_top <== 1;
            sm[i].prev_i0 <== 0;
            sm[i].prev_inew <== 0;
            sm[i].prev_iold <== 0;
            sm[i].prev_na <== 0;
        } else {
            sm[i].prev_top <== sm[i-1].st_top;
            sm[i].prev_i0 <== sm[i-1].st_i0;
            sm[i].prev_inew <== sm[i-1].st_inew;
            sm[i].prev_iold <== sm[i-1].st_iold;
            sm[i].prev_na <== sm[i-1].st_na;
        }
        sm[i].is0 <== isOld0;
        sm[i].fnc <== fnc;
        sm[i].levIns <== smtLevIns.levIns[i];
    }
    sm[nLevels-1].st_na === 1;

    component levels[nLevels];
    for (var i=nLevels-1; i != -1; i--) {
        levels[i] = SMTVerifierLevel();

        levels[i].st_top <== sm[i].st_top;
        levels[i].st_i0 <== sm[i].st_i0;
        levels[i].st_inew <== sm[i].st_inew;
        levels[i].st_iold <== sm[i].st_iold;
        levels[i].st_na <== sm[i].st_na;

        levels[i].sibling <== siblings[i];
        levels[i].old1leaf <== hash1Old.out;
        levels[i].new1leaf <== hash1New.out;

        levels[i].lrbit <== n2bNew.out[i];
        if (i==nLevels-1) {
            levels[i].child <== 0;
        } else {
            levels[i].child <== levels[i+1].root;
        }
    }


    // Check that if checking for non inclussuin and isOld0==0 then key!=old
    component areKeyEquals = IsEqual();
    areKeyEquals.in[0] <== oldKey;
    areKeyEquals.in[1] <== key;

    component keysOk = MultiAND(3);
    keysOk.in[0] <== fnc;
    keysOk.in[1] <== 1-isOld0;
    keysOk.in[2] <== areKeyEquals.out;

    keysOk.out === 0;

    // Check the roots
    levels[0].root === root;

}
