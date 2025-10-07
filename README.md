# FEWer
Collection of scripts to automize a parallelize Amber's FEW protocol (MM-PBSA) on multiple GPUs

## Setup instructions
Create a working directory:
```shell
mkdir MCT1_v3
```

Clone the FEWer repository
```shell
git clone https://github.com/archie18/FEWer.git
```

Create a directory for the molecular structure files:
```shell
mkdir structs
```

Here, we will setup a job with a single receptor protein and many docked ligands. Copy the receptor:
```shell
cp MCT1.pdb structs/
```

Now we need to copy the ligand files. We wil assume they are in a zip file with name `23_lig_x2.zip`. Let's create a subdirectory for them:
```shell
mkdir structs/ligs
```

Copy the ligand zip:
```shell
cp 23_lig_x2.zip structs/ligs
```

Unzip the ligands:
```shell
cd structs/ligs
unzip 23_lig_x2.zip
cd ../..
```

FEWer works with a complex (a pair of protein and ligand) for MMPBSA calculation. We need to setup these complexes with `make_complexes.sh`. Copy the script so we can modify it:
```shell
cp FEWer/make_complexes.sh .
```

Modify the file with your text editor of choice, e.g.:
```shell
vim make_complexes.sh
```

The file should look something like this:
```shell
DIR=structs
REC=MCT1.pdb
LIGS=ligs/*.sdf

cd "$DIR"
BASE=$(basename "$REC" .pdb)

NUM=1
for LIG in $LIGS; do
    echo -n $LIG
    # Get sequential number
    #NUM=$(echo "$LIG" | sed -E 's/.*[^0-9]([0-9]+)\.sdf/\1/')
    cp "$REC" "${BASE}_${NUM}_recep.pdb"
    cp "$LIG" "${BASE}_${NUM}_lig.sdf"
    echo " ${BASE}_${NUM}_lig.sdf"
    #cp "${BASE}_sslink.txt" "${BASE}_${NUM}_sslink.txt"
    #cp "${BASE}_bonds.txt" "${BASE}_${NUM}_bonds.txt"
    ((NUM++))
done
cd ..
```

Run the script to create the complexes:
```shell
./make_complexes.sh
```

Now copy the FEWer run script:
```shell
cp FEWer/run_prod.sh .
```

Modify the run script with your text editor of choice, e.g.:
```shell
vim run_prod.sh
```

The config section should looke something like this:
```shell
########## CONFIGURATION ###########

# Number of parallel CPU jobs
export CPU_count=5

# Available GPUs - use nvidia-smi to get IDs
gpu_ids=(0 1 2 4 5 6)

# Receptor file mask
receptors=(structs/*_recep.pdb)

# mpirun binary
export mpirun_bin=/usr/lib64/openmpi/bin/mpirun

# Use ANTECHAMBER or BABEL to convert from sdf to mol2?
export sdf_to_mol2=ANTECHAMBER

# Number of repetitions
export NREP=5

# Treat formal ligand charge? Does only work if ligans are provided (additionally) in SDF format
export TREAT_CHARGE=1

# Prepare structure with pdb4amber?
export PDB4AMBER=1

###################################
```


## Usage instructions

Obtain summarized results:
```shell
./FEWer/get_all_results.py --met FEW
```
These results can be redirected into a file for convenience:
```shell
./FEWer/get_all_results.py --met FEW > results.txt
```
