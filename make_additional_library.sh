dir=structs
receptor_suffix="_recep.pdb"
for f in $(printf "${dir}/*${receptor_suffix}"); do
    base=$(basename "$f" "$receptor_suffix")
    #grep '^HETATM.*\( CA  \| NA  \| MG  \)' $f > ${dir}/${base}_ions.pdb
    grep '^\(HETATM\|ATOM\).*\( CA \+CA\| NA \+NA\| MG \+MG\| Na+ \+Na+\)' $f > ${dir}/${base}_ions.pdb

    echo source leaprc.protein.ff14SB > leap_ions.in
    echo source leaprc.water.tip3p >> leap_ions.in
    echo ions = loadpdb ${dir}/${base}_ions.pdb >> leap_ions.in
    echo saveoff ions ${dir}/${base}_ions.lib >> leap_ions.in
    echo quit >> leap_ions.in
    tleap -s -f leap_ions.in

done
