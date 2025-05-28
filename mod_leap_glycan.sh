#!/usr/bin/env bash
if [ -f "../bonds_1.txt" ]; then
    echo "Adding glycan setup to leap_script_${1}.in..."
    leap_script="MD_am1/ligand/cryst/leap_script_${1}.in"
    sed -i '/source leaprc.gaff/ a source leaprc.GLYCAM_06j-1' "MD_am1/ligand/cryst/leap_script_${1}.in"
    sed -i '/COM =/ r ../bonds_'${1}'.txt' "MD_am1/ligand/cryst/leap_script_${1}.in"
else
    echo "_bonds.txt not found. Not adding glycan setup."
fi
