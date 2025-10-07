# FEWer
Collection of scripts to automize a parallelize Amber's FEW protocol (MM-PBSA) on multiple GPUs

## Setup instructions
Create a working directory
```bash
mkdir MCT1_v3
```

Clone the FEWer repository
```
git clone https://github.com/archie18/FEWer.git
```

## Usage instructions

Obtain summarized results:
```bash
./FEWer/get_all_results.py --met FEW
```
These results can be redirected into a file for convenience:
```bash
./FEWer/get_all_results.py --met FEW > results.txt
```
