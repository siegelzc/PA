#!/usr/bin/python3
# Assemble the project's assembly language into a hexadecimal file

import sys

if __name__ != '__main__':
    print("assembler.py should be run as the main program", file=sys.stderr)
    sys.exit(2)

if len(sys.argv) == 1 or '--help' in sys.argv:
    print("""Assembler:
    Usage: /assembler.py [FILE].[EXT]
        FILE: A file written in the assembly language described in /README
    Will produce a file named [FILE].hex with the assembled hexadecimal code""")
    sys.exit(0)
if len(sys.argv) < 2:
    print("provide an assembly file as an argument to this program", file=sys.stderr)
    sys.exit(2)


def encodeline(line, linenum):
    stripped = line.strip()
    split = line.split(' ')
    ins = split[0]

    def error_argument_num():
        print("ERROR:{0} '{1}' instruction is given incorrect number of arguments".format(linenum, ins),
              file=sys.stderr)
        sys.exit(1)

    def error_argument_invalid():
        print("ERROR:{0} '{1}' instruction has invalid argument values".format(linenum, ins),
              file=sys.stderr)
        sys.exit(1)

    if ins == 'sub' or ins == 'add' or ins == 'mul':
        try:
            ra = int(split[1][1:])  # The first character of a register is 'r'
            rb = int(split[2][1:])
            rt = int(split[3][1:])
        except ValueError:
            error_argument_invalid()

        if len(split) != 4: error_argument_num()
        if ra > 15 or rb > 15 or rt > 15 or ra < 0 or rb < 0 or rt < 0: error_argument_invalid()

        if ins == 'sub':
            return '0{0:x}{1:x}{2:x}'.format(ra, rb, rt)
        elif ins == 'add':
            return '1{0:x}{1:x}{2:x}'.format(ra, rb, rt)
        elif ins == 'mul':
            return '2{0:x}{1:x}{2:x}'.format(ra, rb, rt)
    elif ins == 'movl' or ins == 'movh':
        try:
            i = int(split[1])
            rt = int(split[2][1:])
        except ValueError:
            error_argument_invalid()

        if len(split) != 3: error_argument_num()
        if i > 255 or rt > 15 or i < 0 or rt < 0: error_argument_invalid()

        if ins == 'movl':
            return '8{0:02x}{1:x}'.format(i, rt)
        elif ins == 'movh':
            return '9{0:02x}{1:x}'.format(i, rt)
    elif ins == 'mov' or ins == 'swp' or \
            ins == 'jz' or ins == 'jnz' or ins == 'js' or ins == 'jns' or \
            ins == 'ld' or ins == 'st':
        try:
            ra = int(split[1][1:])
            rt = int(split[2][1:])
        except ValueError:
            error_argument_invalid()

        if len(split) != 3: error_argument_num()
        elif ra > 15 or rt > 15 or ra < 0 or rt < 0: error_argument_invalid()

        if ins == 'mov':
            return 'b{0:x}0{1:x}'.format(ra, rt)
        elif ins == 'swp':
            return 'b{0:x}1{1:x}'.format(ra, rt)
        elif ins == 'jz':
            return 'e{0:x}0{1:x}'.format(ra, rt)
        elif ins == 'jnz':
            return 'e{0:x}1{1:x}'.format(ra, rt)
        elif ins == 'js':
            return 'e{0:x}2{1:x}'.format(ra, rt)
        elif ins == 'jns':
            return 'e{0:x}3{1:x}'.format(ra, rt)
        elif ins == 'ld':
            return 'f{0:x}0{1:x}'.format(ra, rt)
        elif ins == 'st':
            return 'f{0:x}1{1:x}'.format(ra, rt)
    else:
        print("ERROR:{0} Invalid instruction found".format(linenum), file=sys.stderr)
        sys.exit(1)


for filename in sys.argv[1:]:
    name_length = filename.rfind('.')
    if (name_length == -1): name_length = len(filename)
    outname = '{0}.hex'.format(filename[0:name_length])
    with open(filename, 'r') as sfile:
        with open(outname, 'w') as hexfile:
            linenum = 0
            for line in sfile:
                linenum += 1
                encoding = encodeline(line, linenum)
                hexfile.write('{0}\n'.format(encoding))
            hexfile.write('ffff\n') # End the file with an invalid instruction
