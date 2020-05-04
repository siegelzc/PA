#!/usr/bin/python3
#
# Parse the program's hex file of instructions into a list of instructions
import sys
from enum import Enum


def parse(filename):
    with open(filename, 'r') as hexfile:
        text = hexfile.read()
    lines = text.split('\n')

    instructions = []
    for line in lines:
        if len(line) != 4:
            continue

        opcode = int(line[0], 16)
        ra = int(line[1], 16)
        rb = int(line[2], 16)
        rt = int(line[3], 16)
        imm = int(line[1:3], 16)
        xop = int(line[2], 16)

        isSub = opcode == 0
        isAdd = opcode == 1
        isMul = opcode == 2
        isMovl = opcode == 8
        isMovh = opcode == 9
        isMov = opcode == 11 and xop == 0
        isSwp = opcode == 11 and xop == 1
        isJz = opcode == 14 and xop == 0
        isJnz = opcode == 14 and xop == 1
        isJs = opcode == 14 and xop == 2
        isJns = opcode == 14 and xop == 3
        isLd = opcode == 15 and xop == 0
        isSt = opcode == 15 and xop == 1

        if isSub:
            ins = Instruction.Type.SUB
            instruction = Instruction(ins, ra, rb, rt)
        elif isAdd:
            ins = Instruction.Type.ADD
            instruction = Instruction(ins, ra, rb, rt)
        elif isMul:
            ins = Instruction.Type.MUL
            instruction = Instruction(ins, ra, rb, rt)
        elif isMovl:
            ins = Instruction.Type.MOVL
            instruction = Instruction(ins, imm, rt)
        elif isMovh:
            ins = Instruction.Type.MOVH
            instruction = Instruction(ins, imm, rt)
        elif isMov:
            ins = Instruction.Type.MOV
            instruction = Instruction(ins, ra, rt)
        elif isSwp:
            ins = Instruction.Type.SWP
            instruction = Instruction(ins, ra, rt)
        elif isJz:
            ins = Instruction.Type.JZ
            instruction = Instruction(ins, ra, rt)
        elif isJnz:
            ins = Instruction.Type.JNZ
            instruction = Instruction(ins, ra, rt)
        elif isJs:
            ins = Instruction.Type.JS
            instruction = Instruction(ins, ra, rt)
        elif isJns:
            ins = Instruction.Type.JNS
            instruction = Instruction(ins, ra, rt)
        elif isLd:
            ins = Instruction.Type.LD
            instruction = Instruction(ins, ra, rt)
        elif isSt:
            ins = Instruction.Type.ST
            instruction = Instruction(ins, ra, rt)
        else:
            ins = Instruction.Type.UNDEF
            instruction = Instruction(ins)

        instructions.append(instruction)

    return instructions


class Instruction:
    class Type(Enum):
        SUB = 0
        ADD = 1
        MUL = 2
        MOVL = 8
        MOVH = 9
        MOV = 110
        SWP = 111
        JZ = 140
        JNZ = 141
        JS = 142
        JNS = 143
        LD = 150
        ST = 151
        UNDEF = -1

    def __init__(self, ins, *args):
        self.ins = ins;

        if ins == Instruction.Type.SUB or ins == Instruction.Type.ADD or ins == Instruction.Type.MUL:
            self.ra = args[0]
            self.rb = args[1]
            self.rt = args[2]
        elif ins == Instruction.Type.MOVL or ins == Instruction.Type.MOVH:
            self.imm = args[0]
            self.rt = args[1]
        elif ins == Instruction.Type.MOV or ins == Instruction.Type.SWP or ins == Instruction.Type.JZ or ins == Instruction.Type.JNZ or ins == Instruction.Type.JS or ins == Instruction.Type.JNS or ins == Instruction.Type.LD or ins == Instruction.Type.ST:
            self.ra = args[0]
            self.rt = args[1]
