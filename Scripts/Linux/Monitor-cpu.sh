#!/bin/bash
. ~/.bash_profile
export DATE=$(date +"%d%b%y %R")
echo "================= ${DATE}" >> /home/oracle/scripts/monitor_cpu.log
top -b -c -o +%CPU | head -n 20  >> /home/oracle/scripts/monitor_cpu.log
echo "<<<<<<<<<<<<<<<<<<<<<<<<"  >> /home/oracle/scripts/monitor_cpu.log