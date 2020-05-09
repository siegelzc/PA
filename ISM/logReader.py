#!/usr/bin/python3

import sys
import csv
from parser import *

mem = [None] * 65535
regs = ['0000'] + [None] * 15
memLog = []
regsLog = []
pcLog = []


def buildcsv(filename, logname):
    with open(filename, 'r') as hexfile:
        text = hexfile.read()
    lines = text.split('\n')

    for i in range(0, len(lines)):
        if (len(lines[i]) == 4):
            mem[2 * (i - 1)] = lines[i][0:2]
            mem[2 * i - 1] = lines[i][2:4]

    with open(logname, 'r') as logfile:
        log = logfile.read()
    lines = log.split('\n')

    for line in lines:
        args = line.split()
        if (len(args) > 0):
            pcLog.append(args[0])
            if (args[1] == "m"):
                mem[int(args[2])] = args[3][0:2]
                mem[int(args[2]) + 1] = args[3][2:4]
            elif (args[1] == "r"):
                if (int(args[2]) != 0): regs[int(args[2])] = args[3]

            regsLog.append(regs[:])
            memLog.append(mem[:])

    with open("./logs/vlog_mem.csv", "w") as log:
        wr = csv.writer(log, delimiter="\n")
        wr.writerow(memLog)

    with open("./logs/vlog_regs.csv", "w") as log:
        wr = csv.writer(log, delimiter="\n")
        wr.writerow(regsLog)

    with open("./logs/vlog_pc.csv", "w") as log:
        wr = csv.writer(log, delimiter="\n")
        wr.writerow(pcLog)


if __name__ == '__main__':
    buildcsv(sys.argv[1], sys.argv[2])
