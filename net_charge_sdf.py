#!/usr/bin/env python3

import sys

if __name__ == "__main__":
    net_charge = 0
    with open(sys.argv[1]) as f:
        for line in f:
            line = line.strip()
            if line.startswith("M  CHG"):
                tokens = line.split()
                if tokens[1] == "CHG":
                    for i in range(int(tokens[2])):
                        atmid = tokens[3+i*2]
                        charge = int(tokens[4+i*2])
                        net_charge += charge
    print(net_charge)
