# Antechamber does not work with atom names > 3 characters of lenght.
# This Python3 script fixes this.
# Also sets any user charges to zero, as requiered by Antechamber.

# for f in structs/*_lig.mol2; do cp $f $f.bak; python3 fix_atom_names_mol2.py $f.bak > $f; done

import sys

with open(sys.argv[1]) as f:
    start = False
    indices = {}
    for line in f:
        if start and line.startswith("@"):
            start = False
        if start:
            tokens = line.split()
            # Rename atoms
            atomname = tokens[1]
            atomname = ''.join([i for i in atomname if not i.isdigit()]) # Remove any numbers from the atom name
            if not atomname in indices:
                indices[atomname] = 1
            else:
                indices[atomname] += 1
            atomname = atomname+str(indices[atomname])
            # Set charge to zero
            if len(tokens) >= 9:
                tokens[8] = "0.000"
            print(tokens[0], atomname, " ".join(tokens[2:]), sep=" ")
        else:
            print(line, end='')
        if line.startswith("@<TRIPOS>ATOM"):
            start = True
