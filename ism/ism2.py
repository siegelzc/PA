import sys
from parser import *

mem = [None] * 65535
regs = ['0000'] + [None] * 15

with open(sys.argv[1], 'r') as hexfile:
    text = hexfile.read();

lines = text.split('\n')

for i in range (0,len(lines)):
    if(len(lines[i]) == 4):
        mem[2*i] = lines[i][0:2]
        mem[2*i+1] = lines[i][2:4]

#print(mem)

pc = 0;
print("type c to continue, q to quit, r to print register, and m to print memory")
while True:
    
    ui = input()
    while(ui != "c"):
        if(ui == "q"): sys.exit()
        if(ui == "r"): print(regs)
        if(ui == "m"): print(mem)
        ui = input()
    print(mem[pc]+mem[pc+1])

    ins = parse(mem[pc]+mem[pc+1])
    value = None;
    
    typ = ins.ins
    va = int(regs[ins.ra], 16) if ins.ra and regs[ins.ra] else None
    vb = int(regs[ins.rb], 16) if ins.rb and regs[ins.rb] else None
    vt = int(regs[ins.rt], 16) if ins.rt and regs[ins.rt] else None
    
    if(typ == Instruction.Type.UNDEF): 
        break
    elif(typ == Instruction.Type.SUB): 
        value = va - vb
    elif(typ == Instruction.Type.ADD): 
        value = va + vb
    elif(typ == Instruction.Type.MUL): 
        value = va * vb
    elif(typ == Instruction.Type.MOVL):
        value = ins.imm
    elif(typ == Instruction.Type.MOVH):
        value = ins.imm*16**2+vt
    elif(typ == Instruction.Type.MOV):
        value = va
    elif(typ == Instruction.Type.SWP):
        value = va
        regs[ra] = regs[rt]
    elif(typ == Instruction.Type.LD):
        value = int(mem[va]+mem[va+1],16)
    elif(typ == Instruction.Type.ST):
        mem[va] = '{0:0{1}X}'.format(vt,2)[0:2]
        mem[va+1] = '{0:0{1}X}'.format(vt,2)[2:4]
    
    if(value != None):
        if(ins.rt == 0): print("printing:", chr(value), end = '')
        else: regs[ins.rt] = '{0:0{1}X}'.format(value,4)
    
    if(typ == Instruction.Type.JZ and va == 0):
        pc = vt;
    elif(typ == Instruction.Type.JNZ and va != 0):
        pc = vt;
    elif(typ == Instruction.Type.JS and va < 0):
        pc = vt;
    elif(typ == Instruction.Type.JNS and va >= 0):
        pc = vt;
    else:
        pc+=2;

    #print(regs)
    
