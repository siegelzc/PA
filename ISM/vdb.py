#!/usr/bin/python3
# Debugging tool for Verilog/Assembly in CS429H

import os
import argparse
import assembler
from ism3 import model
from logReader import buildcsv

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

os.system('mkdir {0}/logs'.format(scriptdir))
os.system('rm -r {0}/logs/*'.format(scriptdir))
assembler.assemblefile(aspath)
os.system('{0}/ism3.py {1}'.format(scriptdir, hexpath))
os.system('cat {0} > {1}/mem.hex'.format(hexpath, cpudir))
os.chdir(cpudir)
os.system('./{0} > cpu.out'.format(os.path.basename(cpupath)))
os.chdir(scriptdir)
buildcsv(hexpath, cpudir + '/cpu.log')
os.system('{0}/debugger.py {0}/logs/ism_pc.csv {0}/logs/vlog_pc.csv {0}/logs/ism_regs.csv '
          '{0}/logs/vlog_regs.csv {0}/logs/ism_mem.csv {0}/logs/vlog_mem.csv'.format(scriptdir))
