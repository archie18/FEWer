# FEWer
Collection of scripts to automize a parallelize Amber's FEW protocol (MM-PBSA) on multiple GPUs

## Setup instructions (one receptor and many ligands)
Create a working directory:
```shell
mkdir MCT1_v3
cd MCT1_v3
```

Clone the FEWer repository
```shell
git clone https://github.com/schuellerlab/FEWer.git
```

Create a directory for the molecular structure files:
```shell
mkdir structs
```

Here, we will setup a job with a single receptor protein and many docked ligands. The receptor should be in PDB format without hydrogen atoms. Copy the receptor:
```shell
cp MCT1.pdb structs/
```

Now we need to copy the ligand files. Ligands need to be provided full-atom (with hydrogen atoms) and coordinates corresponding to the protein-ligand complex. SDF format is preferred. If ligands are provided as MOL2 files, you still need to provide an SDF version of each ligand that we need in order to determine the formal charge. When providing MOL2 files, use configuration option `export sdf_to_mol2=USE_MOL2` (see below). We will assume ligands are in a zip file with name `23_lig_x2.zip`. Let's create a subdirectory for them:
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

Now we are ready to run the calculations.

## Setup instructions (many receptor-ligand complexes)
Create a working directory:
```shell
mkdir fXa_dock_v2
cd fXa_dock_v2
```

Clone the FEWer repository
```shell
git clone https://github.com/schuellerlab/FEWer.git
```

Create a directory for the molecular structure files:
```shell
mkdir structs
```

Copy receptor and ligand files to the `structs` directory. Filenames must start with the same prefix, e.g.:
```shell
2bq7_lig.mol2
2bq7_lig.sdf
2bq7_recep.pdb
2fzz_lig.mol2
2fzz_lig.sdf
2fzz_recep.pdb
```
See the section above for notes on SDF/MOL2 format.

Now we need to prepare bound ions. Run the script:
```shell
FEWer/make_additional_library.sh
```

The `structs` directory now should look like this:
```shell
2bq7_ions.lib
2bq7_ions.pdb
2bq7_lig.mol2
2bq7_lig.sdf
2bq7_recep.pdb
2fzz_ions.lib
2fzz_ions.pdb
2fzz_lig.mol2
2fzz_lig.sdf
2fzz_recep.pdb
```

Now copy the FEWer run script and check the configuration section of the file for any options to be changed:
```shell
cp FEWer/run_prod.sh .
vim run_prod.sh
```

Now we are ready to run the calculations.

## Setup instructions (advanced)
Disulphide bridges are taken care of internally, as detected by `pdb4amber`. However, you may provide additional an additional file `_sslink.txt` file, e.g.:
```shell
cat structs/6y5f_26_sslink.txt 
10	135
44	141
93	112
117	122
159	169
194	230
219	334
371	406
375	413
387	471
401	482
416	490
450	454
```
Columns are seperated by a tab caracter.

Covalent bonds for tleap setup (e.g. glycolisations) may be provided by a `_bonds.txt` file, e.g.:
```shell
cat structs/6y5f_26_bonds.txt 
bond <name>.514.C1 <name>.118.ND2
bond <name>.518.C1 <name>.330.ND2
bond <name>.514.O4 <name>.515.C1
bond <name>.515.O4 <name>.516.C1
bond <name>.516.O3 <name>.517.C1
bond <name>.518.O4 <name>.519.C1
bond <name>.519.O4 <name>.520.C1
bond <name>.520.O3 <name>.521.C1
```
Run the `FEWer/mod_FEW_for_glycan.sh` script before doing calculations with glycans.


## Usage instructions (run calculations)
You should run calculations inside a detachable session, e.g. with screen. Source the Amber shell file and then execute the run script: 
```shell
screen
source FEWer/amber.sh
./run_prod.sh
```

To detach the screen session press `Ctrl-a` then `d`. To resume the session run:
```
screen -r
```

Check the log files for any errors or warnings, e.g.:
```shell
less gpu_id_0.out
```
Press `q` to close the `less` viewer.

To check the progress run:
```shell
./FEWer/progress.sh
```

Obtain summarized results:
```shell
./FEWer/get_all_results.py
```

These results can be redirected into a file for convenience:
```shell
./FEWer/get_all_results.py > results.txt
```
