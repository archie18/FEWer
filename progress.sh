#!/usr/bin/env bash
num_recep=$(ls -1 structs/*_recep.pdb | wc -l)
iterations=$(cat runFEW.sh | grep NREP= | grep -Eo [0-9]+)

let max=$num_recep*$iterations;
progress=$(grep "\* Status:     finished" gpu_id_*.out | wc -l)
perc=$(bc -l <<< "$progress/$max*100"); perc=$(bc <<< "scale=2; $perc/1")

start_sec=$(grep "\* Start date:" gpu_id_*.out | awk '{ split($0, parts, "* Start date: "); print parts[2];}' | date -f - +%s | sort | head -1)
end_sec=$(grep "\* End date:" gpu_id_*.out | awk '{ split($0, parts, "* End date: "); print parts[2];}' | date -f - +%s | sort | tail -1)
start=$(date -d @"$start_sec")
end=$(date -d @"$end_sec")
dif_h=$(bc -l <<< "($end_sec - $start_sec) / 60 / 60")
dif_m=$(bc -l <<< "($end_sec - $start_sec) / 60")
speed=$(bc -l <<< "$dif_m / $progress")
dif=$(bc <<< "scale=2; $dif_h/1")
speed=$(bc <<< "scale=2; $speed/1")

let remaining_it=$max-$progress
remaining_min=$(bc <<< "scale=0; $remaining_it * $speed / 1")
date_finished=$(date -d ${remaining_min}min)

error_count=$(grep -vf error_exclude.txt gpu_id_*.out | grep -i error | wc -l)
min_energy=$(./get_all_results.py --met FEW | cut -f3 | tail -n +2 | awk '{if(min==""){min=$1}; if($1<min) {min=$1}} END {print min}')

echo "Max:         $max"
echo "Progress:    $progress"
echo "%Progress:   ${perc}%"
echo "Start:       $start"
echo "End:         $end"
echo "Diff:        $dif h"
echo "Speed:       $speed min/iteration"
echo "Finish date: $date_finished"
echo "Min energy:  $min_energy kcal/mol"
echo "Error count: $error_count"
