#!/usr/bin/env bash

export CPU_count=4
gpu_ids=(0 1 2 4 5 6 7)
receptors=(structs/*_recep.pdb)
export mpirun_bin=/usr/lib64/openmpi/bin/mpirun

gpu_count=${#gpu_ids[@]}
rec_count=${#receptors[@]}

split_list_evenly() {
  local num_chunks=$1
  shift
  local list=("$@")

  local total_elements=${#list[@]}
  local base_chunk_size=$(( total_elements / num_chunks ))
  local remainder=$(( total_elements % num_chunks ))
  local index=0

  local result=()

  for ((chunk=0; chunk<num_chunks; chunk++)); do
    local size=$base_chunk_size
    if (( chunk < remainder )); then
      size=$((size + 1))
    fi

    local chunk_items=("${list[@]:index:size}")
    result+=("$(printf "%s " "${chunk_items[@]}")")
    index=$((index + size))
  done

  # Print the result, one chunk per line
  printf '%s\n' "${result[@]}"
}

# Get receptor basename
basenames=()
for rec in "${receptors[@]}"; do
    base=$(basename "$rec" _recep.pdb)
    basenames+=("$base")
done

# Split receptors into gpu_count chunks and capture the output
mapfile -t chunks < <(split_list_evenly gpu_count "${basenames[@]}")

# Now iterate over the chunks
gpu_idx=0
PIDs=""
for chunk in "${chunks[@]}"; do
    gpu_id=${gpu_ids[gpu_idx]}
    echo "GPU ID: $gpu_id"
    echo "Chunk:"
    for item in $chunk; do
        echo "  $item"
    done
    # Run FEW
    ./FEWer/runFEW.sh $gpu_id $chunk > gpu_id_${gpu_id}.out 2>&1 & PID=$!
    PIDs="${PIDs} ${PID}"
    echo "PID: ${PID}"
    echo "---"
    gpu_idx=$((gpu_idx+1))
    if [ $gpu_idx -ge ${#gpu_ids[@]} ]; then
        gpu_idx=0
    fi
done
echo "Process IDs:${PIDs}"
exit

