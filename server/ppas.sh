#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling qfserver
/usr/bin/as -o /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/lib/loongarch64-linux/QFServer.o  -mabi=lp64 /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/lib/loongarch64-linux/QFServer.s
if [ $? != 0 ]; then DoExitAsm qfserver; fi
rm /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/lib/loongarch64-linux/QFServer.s
echo Linking /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer
OFS=$IFS
IFS="
"
/usr/bin/ld   -Ttext-segment=0x550000 --dynamic-linker=/lib64/ld.so.1      -L. -o /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer -T /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/link12153.res -e _start
if [ $? != 0 ]; then DoExitLink /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer; fi
IFS=$OFS
echo Linking /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer
OFS=$IFS
IFS="
"
/usr/bin/objcopy --only-keep-debug /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer.dbg
if [ $? != 0 ]; then DoExitLink /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer; fi
IFS=$OFS
echo Linking /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer
OFS=$IFS
IFS="
"
/usr/bin/objcopy "--add-gnu-debuglink=/home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer.dbg" /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer
if [ $? != 0 ]; then DoExitLink /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer; fi
IFS=$OFS
echo Linking /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer
OFS=$IFS
IFS="
"
/usr/bin/strip --strip-unneeded /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer
if [ $? != 0 ]; then DoExitLink /home/lbz/fpcupdeluxe/QFDataSet_unidac/server/QFServer; fi
IFS=$OFS
