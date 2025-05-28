#!/usr/bin/env bash
#
# USAGE
# sh runFEW.sh <gpu_id> <basename_1> [<basename_2> <basename_3> ...]
# base_name: Receptor and ligand base filename
# gpu_id:    ID of the GPU to use
#
# HISTORY
# 2025-05-23    0.4    Andreas    Using FEW.pl within Amber path
#                                 Made _ions.lib optional
#                                 Added _bonds.txt for optional extra 'bond' commands for the
#                                 protein Leap setup, e.g. for glycan linking
#                                 Made pdb4amber optional
# 2025-05-16    0.3    Andreas    Using SDF format once again and added optional _sslink.txt
#                                 to define disulfide bridges.

# Number of repetitions
NREP=5

# Treat formal ligand charge? Does only work if ligans are provided (additionally) in SDF format
TREAT_CHARGE=1

# Prepare structure with pdb4amber?
PDB4AMBER=0

# Command line parsing
gpu_id="$1"
basenames=("${@:2}")

# Assign GPU
export CUDA_VISIBLE_DEVICES="$gpu_id"

# Iterate over basenames
for base in "${basenames[@]}"; do
    ### Preparation
    echo "============================================================="
    echo "= GPU ID:     $gpu_id"
    echo "= Base:       $base"
    echo "= Status:     running..."
    echo "= Start date: $(date)"
    echo "============================================================="
    mkdir -p "$base"
    cd "$base"
    rec="${base}_recep.pdb"
    lig="${base}_lig.sdf"
    #lig="${base}_lig.mol2"
    
    # Sanitize protein
    pdb4amber -i ../structs/"${rec}" -o receptor_prep.pdb --add-missing-atoms --no-conect --nohyd
    # If PDB4AMBER is unset or zero do not sanitize the protein with pdb4amber. We still need to
    # run pdb4amber to get the number of receptor residues later on.
    if [[ -z PDB4AMBER || PDB4AMBER -eq 0 ]]; then
        echo "Not using pdb4amber."
        cp ../structs/"${rec}" receptor_prep.pdb
    fi

    # Convert space to tab in sslink file
    awk -v OFS="\t" '$1=$1' receptor_prep_sslink > disulfide_bridges.txt

    # Use _sslink.txt file, if exists
    if [ -f "../structs/${base}_sslink.txt" ]; then
        echo "Will use ${base}_sslink.txt file to define disulfide bridges."
        cp ../structs/${base}_sslink.txt disulfide_bridges.txt
    fi

    # Convert ligand format with antechamber
    mkdir -p ligs
    antechamber -i ../structs/"${lig}" -fi sdf -o ligs/ligand.mol2 -fo mol2

    cp ../cfiles/leap_am1 .

    # Treat charged ligands
    rm -f lig_charge_file
    if [[ -v TREAT_CHARGE && TREAT_CHARGE -ne 0 ]]; then
        charge=$(grep "M  CHG" ../structs/"${base}_lig.sdf" | awk '{print $NF}' )
        if [ -n "$charge" ]; then
            echo "Ligand charge: $charge"
            sed -i 's/^non_neutral_ligands.*/non_neutral_ligands          1/' leap_am1
            echo -e "ligand.mol2\t${charge}" > lig_charge_file 
        else
            echo "Ligand is not charged"
        fi
    else
        echo "Not treating ligand formal charge."
    fi

    # Prepare MD
    numres=$(cat receptor_prep_renum.txt | grep -v HOH | grep -v WAT | tail -1 | awk '{print $NF}') # Get number of residues of the receptor
    cp ../cfiles/setup_am1_1trj_MDs .
    sed -i 's/^no_of_rec_residues.*/no_of_rec_residues          '${numres}'/' setup_am1_1trj_MDs 

    # Prepare MMPBSA
    cp ../cfiles/mmpbsa_am1_1trj_pb3_gb0 .
    sed -i 's/^no_of_rec_residues.*/no_of_rec_residues        '${numres}'/' mmpbsa_am1_1trj_pb3_gb0

    # Copy crystallographic ions library OFF file
    # Needs to be prepared separately with the make_additional_library.sh script
    if [ -f "../structs/${base}_ions.lib" ]; then
        cp "../structs/${base}_ions.lib" ions.lib
    else
        touch ions.lib
    fi

    # Copy and prepare optional leap bonds file, e.g. for glycan linking
    if [ -f "../structs/${base}_bonds.txt" ]; then
        cp "../structs/${base}_bonds.txt" _bonds.txt
        sed 's/<name>/COM/g' _bonds.txt > bonds_2.txt
        cp bonds_2.txt bonds_1.txt
        sed 's/<name>/REC/g' _bonds.txt >> bonds_1.txt
    fi

    ### Run MD and MMPBSA
    for i in $(seq 1 $NREP); do
        echo "******************************************"
        echo "* Iteration:  $i"
        echo "* Status:     running..."
        echo "* GPU ID:     $gpu_id"
        echo "* Base:       $base"
        echo "* Start date: $(date)"
        echo "******************************************"
        mkdir -p $i # Create sequentially numbered directory
        cd $i # Change to new work directory
        #leap_am1
        perl "${AMBERHOME}"/AmberTools/src/FEW/FEW.pl MMPBSA ../leap_am1
        #setup_am1_1trj_MDs
        perl "${AMBERHOME}"/AmberTools/src/FEW/FEW.pl MMPBSA ../setup_am1_1trj_MDs
        # Replace qsub with csh
        sed -i 's/qsub/csh/' ./MD_am1/qsub_equi.sh
        sed -i 's/qsub/csh/' ./MD_am1/qsub_MD.sh
        # Run equilibration
        echo "Running equilibration..."
        ./MD_am1/qsub_equi.sh
        # Run production
        echo "Running production..."
        ./MD_am1/qsub_MD.sh
        #MMPBSA
        cp ../mmpbsa_am1_1trj_pb3_gb0 .
        #sed -i "s+/home/user/tutorial+${CWD}+g" "$CWD"/cfiles/mmpbsa_am1_1trj_pb3_gb0
        sed -i 's#^output_path.*#output_path                  '$(pwd)'#' mmpbsa_am1_1trj_pb3_gb0
        sed -i 's#^mmpbsa_batch_path.*#mmpbsa_batch_path         '$(pwd)'#' mmpbsa_am1_1trj_pb3_gb0
        perl "${AMBERHOME}"/AmberTools/src/FEW/FEW.pl MMPBSA mmpbsa_am1_1trj_pb3_gb0
        sed -i 's/qsub/csh/' ./calc_a_1t/qsub_s81_100_1_pb3_gb0.sh
        echo "Running MM-PBSA..."
        ./calc_a_1t/qsub_s81_100_1_pb3_gb0.sh    
        cd ..
        echo "*****************************************"
        echo "* Iteration:  $i"
        echo "* Status:     finished"
        echo "* GPU ID:     $gpu_id"
        echo "* Base:       $base"
        echo "* End date:   $(date)"
        echo "*****************************************"
    done
    cd ..
    echo "============================================================="
    echo "= GPU ID:   $gpu_id"
    echo "= Base:     $base"
    echo "= Status:   finished"
    echo "= End date: $(date)"
    echo "============================================================="
done


