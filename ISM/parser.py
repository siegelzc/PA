# Parse the program's hex file of instructions into a list of instructions
from enum import Enum


def parse(line):
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

    return instruction


class Instruction:
    class Type(Enum):
        SUB = 0
        ADD = 1
        MUL = 2
        MOVL = 8
        MOVH = 9
        MOV = 110
        JZ = 140
        JNZ = 141
        JS = 142
        JNS = 143
        LD = 150
        ST = 151
        UNDEF = -1

    def __init__(self, op, *args):
        self.op = op

        if (op == Instruction.Type.SUB): self.str = 'sub'
        elif (op == Instruction.Type.ADD): self.str = 'add'
        elif (op == Instruction.Type.MUL): self.str = 'mul'
        elif (op == Instruction.Type.MOVL): self.str = 'movl'
        elif (op == Instruction.Type.MOVH): self.str = 'movh'
        elif (op == Instruction.Type.MOV): self.str = 'mov'
        elif (op == Instruction.Type.JZ): self.str = 'jz'
        elif (op == Instruction.Type.JNZ): self.str = 'jnz'
        elif (op == Instruction.Type.JS): self.str = 'js'
        elif (op == Instruction.Type.JNS): self.str = 'jns'
        elif (op == Instruction.Type.LD): self.str = 'ld'
        elif (op == Instruction.Type.ST): self.str = 'st'

        if (op == Instruction.Type.SUB or op == Instruction.Type.ADD or op == Instruction.Type.MUL):
            self.ra = args[0]
            self.rb = args[1]
            self.rt = args[2]
        elif (op == Instruction.Type.MOVL or op == Instruction.Type.MOVH):
            self.ra = None
            self.rb = None
            self.imm = args[0]
            self.rt = args[1]
        elif (op == Instruction.Type.MOV or op == Instruction.Type.JZ
              or op == Instruction.Type.JNZ or op == Instruction.Type.JS or op == Instruction.Type.JNS
              or op == Instruction.Type.LD or op == Instruction.Type.ST):
            self.ra = args[0]
            self.rb = None
            self.rt = args[1]
        else:
            self.ra = None
            self.rb = None
            self.rt = None
