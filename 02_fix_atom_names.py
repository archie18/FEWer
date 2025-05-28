import sys

with open(sys.argv[1]) as f:
    i = 1
    for line in f:
        if line.startswith("HETATM"):
            atomname = line[12:16].rstrip()
            atomname = ''.join([i for i in atomname if not i.isdigit()]) # Remove any numbers from the atom name
            atomname = '{msg: <4}'.format(msg=atomname+str(i))
            print(line[0:12] + atomname + line[16:], end='')
            i += 1
        else:
            print(line, end='')
