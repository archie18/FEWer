DIR=structs
REC=6y5f.pdb
LIGS=130_top_seeds_*.sdf

cd "$DIR"
BASE=$(basename "$REC" .pdb)

for LIG in $LIGS; do
    echo $LIG
    # Get sequential number
    NUM=$(echo "$LIG" | sed -E 's/.*[^0-9]([0-9]+)\.sdf/\1/')
    cp "$REC" "${BASE}_${NUM}_recep.pdb"
    cp "$LIG" "${BASE}_${NUM}_lig.sdf"
    cp "${BASE}_sslink.txt" "${BASE}_${NUM}_sslink.txt"
    cp "${BASE}_bonds.txt" "${BASE}_${NUM}_bonds.txt"
done
cd ..
