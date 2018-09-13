STARTTIME=$(date +%s%N)

clang -I ../../include -emit-llvm -g -c $1.c
/home/osboxes/klee-3.4/klee_build_dir/bin/klee --search=dfs --no-output --warnings-only-to-file --optimize $1.bc

ENDTIME=$(date +%s%N)
ELAPSED_TIME=$((($ENDTIME - $STARTTIME)/1000000))

echo $1 $ELAPSED_TIME
