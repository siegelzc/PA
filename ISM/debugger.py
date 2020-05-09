#!/usr/bin/python3

import csv
import sys

pc0 = []
pc1 = []
mem0 = []
mem1 = []
regs0 = []
regs1 = []


with open(sys.argv[1], newline='') as f:
    reader = csv.reader(f)
    pc0 = list(reader)
with open(sys.argv[2], newline='') as f:
    reader = csv.reader(f)
    pc1 = list(reader)
with open(sys.argv[3], newline='') as f:
    reader = csv.reader(f)
    regs0 = list(reader)
with open(sys.argv[4], newline='') as f:
    reader = csv.reader(f)
    regs1 = list(reader)
with open(sys.argv[5], newline='') as f:
    reader = csv.reader(f)
    mem0 = list(reader)
with open(sys.argv[6], newline='') as f:
    reader = csv.reader(f)
    mem1 = list(reader)

if not(len(pc0) == len(pc1) == len(regs0) == len(regs1) == len(mem0) == len(mem1)):
    print("All Files are NOT the same Dimension")
    sys.exit(1)

print("\nThe following commands can be used:\n",
      "\tq to quit\n",
      "\tc to continue\n",
      "\tr to print entire register file\n",
      "\tr[start:end] to print a range of registers\n",
      "\tm to print entire memory file\n",
      "\tm[start:end] to print a range of memory\n")


i = 0

for i in range(0, len(pc0)) :
    print("ISM:", pc0[i])
    print("LOG:", pc1[i])
    ui = input("\n>>")
    
    while (ui != "c"):
        
        if ("q" in ui): 
            sys.exit()
        if (ui == "r"): 
            print("ISM:", regs0[i])
            print("LOG:", regs1[i])
        if (ui == "m"): 
            print("ISM:", mem0[i])
            print("LOG:", mem1[i])
        if ("[" in ui):
            start = int(ui[ui.find("[") + 1: ui.find(":")])
            end = int(ui[ui.find(":") + 1: ui.find("]")])
            if ("r" in ui): 
                print("ISM:", regs0[i][start:end])
                print("LOG:", regs1[i][start:end])
            if ("m" in ui): 
                print("ISM:", mem0[i][start:end])
                print("LOG:", mem1[i][start:end])
    
        ui = input("\n>>")

print("Program has terminated")
