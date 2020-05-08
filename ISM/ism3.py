#!/usr/bin/python3

import sys
import csv
from parser import *

mem = [None] * 65535
regs = ['0000'] + [None] * 15
memLog = []
regsLog = []


def sval(num):
    """Evaluate the 2's complement signed decimal value of a number"""
    binary = '{0:016b}'.format(num)
    if binary[0] == '0':
        return num
    else:
        short = binary[1:]
        neg = '{:0b}'.format(~int(short, 2))[-15:]
        val = -(int(neg, 2) + 1)
        return val


with open(sys.argv[1], 'r') as hexfile:
    text = hexfile.read()

lines = text.split('\n')

f = open("ism.out", "w")

for i in range(0, len(lines)):
    if (len(lines[i]) == 4):
        mem[2 * i] = lines[i][0:2]
        mem[2 * i + 1] = lines[i][2:4]

pc = 0
output = ""
while True:

    regsLog.append(regs[:])
    memLog.append(mem[:])

    ins = parse(mem[pc] + mem[pc + 1])
    value = None

    typ = ins.op
    va = int(regs[ins.ra], 16) if ins.ra and regs[ins.ra] else None
    vb = int(regs[ins.rb], 16) if ins.rb and regs[ins.rb] else None
    vt = int(regs[ins.rt], 16) if ins.rt and regs[ins.rt] else None

    if (typ == Instruction.Type.UNDEF):
        break
    elif (typ == Instruction.Type.SUB):
        value = sval(va) - sval(vb)
    elif (typ == Instruction.Type.ADD):
        value = sval(va) + sval(vb)
    elif (typ == Instruction.Type.MUL):
        value = sval(va) * sval(vb)
    elif (typ == Instruction.Type.MOVL):
        immb = '{0:08b}'.format(ins.imm)
        sex = '{0:b}'.format(ins.imm).rjust(16, immb[0])
        value = int(sex, 2)
    elif (typ == Instruction.Type.MOVH):
        value = (ins.imm << 8) + vt % 2 ** 8
    elif (typ == Instruction.Type.MOV):
        value = va
    elif (typ == Instruction.Type.SWP):
        value = va
        regs[ins.ra] = regs[ins.rt]
    elif (typ == Instruction.Type.LD):
        try:
            value = int(mem[va] + mem[va + 1], 16)
        except TypeError:  # TypeError occurs if either of the memory bytes are undefined
            print("WARNING:{0} Loading an undefined value from memory".format(ins.str), file=sys.stderr)
    elif (typ == Instruction.Type.ST):
        mem[vt] = '{0:0{1}X}'.format(va, 2)[0:2]
        mem[vt + 1] = '{0:0{1}X}'.format(va, 2)[2:4]

    if (value is not None):
        if (ins.rt == 0):
           print(end='') # print(chr(value), end='')
        else:
            regs[ins.rt] = '{0:0{1}X}'.format(value, 4)[-4:]

    if (typ == Instruction.Type.JZ and va == 0):
        pc = vt
    elif (typ == Instruction.Type.JNZ and va != 0):
        pc = vt
    elif (typ == Instruction.Type.JS and sval(va) < 0):
        pc = vt
    elif (typ == Instruction.Type.JNS and sval(va) >= 0):
        pc = vt
    else:
        pc += 2
    
    s = ""
    if(typ == Instruction.Type.ST): s = "m["+'{0:0{1}X}'.format(vt, 4)+"] = " + '{0:0{1}X}'.format(va, 4) 
    elif(value != None): s = "r[" + '{0:0{1}X}'.format(ins.rt, 4) + "] = " + '{0:0{1}X}'.format(value, 4)
    else: s = 'pc = {0:0{1}X}'.format(pc, 4)
    
    

    output += ( '{0:0{1}X}'.format(pc, 4) + " " + str(typ) + s + "\n")

f.write(output)
f.close()


