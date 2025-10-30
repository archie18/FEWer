ls -1 structs/*_recep.pdb | xargs --replace -- basename '{}' _recep.pdb | sort > all_codes.txt
./FEWer/get_all_results.py | tail -n +2 | cut -f2 | sort > completed_codes.txt
grep -F -x -v -f completed_codes.txt all_codes.txt | sort > missing_codes.txt
