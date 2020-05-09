#!/usr/bin/python3
# Debugging tool for Verilog/Assembly in CS429H

import os
import argparse
import assembler
import ISM.ism3

parser = argparse.ArgumentParser(description="Debugging tool for Verilog/Assembly in CS429H")
parser.add_argument('assembly', metavar='ASSEMBLY', type=str, help='The path to the assembly file to debug')
parser.add_argument('cpu', metavar='CPU', type=str, help='The path to the verilog simulation executable')
args = parser.parse_args()
asfile = vars(args).get('assembly')
cpu = vars(args).get('cpu')

scriptpath = os.path.realpath(__file__)
scriptdir = os.path.dirname(scriptpath)
aspath = os.path.realpath(asfile)
asdir = os.path.dirname(aspath)
cpupath = os.path.realpath(cpu)
cpudir = os.path.dirname(cpupath)
hexpath = assembler.getoutname(aspath)

assembler.assemblefile(aspath)
ISM.ism3.model(hexpath)
os.system('cat {0} > {1}/mem.hex'.format(hexpath, cpudir))
os.chdir(cpudir)
os.system('./{0} > cpu.out'.format(os.path.basename(cpupath)))
os.chdir(scriptdir)
