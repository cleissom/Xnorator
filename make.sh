#!/bin/env bash

SIMULATOR_EXE=build/cleissom_work_xnorator_simple_system_0/sim-verilator/Vibex_simple_system
GEN_DATA_SCRIPT=utils/gen-data.py
BIN_CONV_SCRIPT=utils/bin-conv.py

tests=("acc" "binary" "simple")

if [[ -n "$2" ]]; then
    case "$2" in
        simple)
            SW_ELF=../sw/binconv-simple/binconv-simple.elf
            ;;
        binary)
            SW_ELF=../sw/binconv-binary/binconv-binary.elf
            ;;
        acc)
            SW_ELF=../sw/binconv-acc/binconv-acc.elf
            ;;

    esac
fi

if [ ! -d ./run ]; then
  mkdir -p ./run;
fi

build() {
    fusesoc --cores-root=. run --target=sim --setup --build cleissom:work:xnorator_simple_system --RV32E=0 --RV32M=ibex_pkg::RV32MFast --RV32B=ibex_pkg::RV32BBalanced
}

build_solo() {
    fusesoc --verbose --cores-root=. run --target=synth --setup --build cleissom:work:xnorator_core
}

run() {
    [[ -z "${SW_ELF}" ]] && (echo "Missing argument"; exit 1;)
    cd run
	../${SIMULATOR_EXE} -t --meminit=ram,${SW_ELF}
	cd -
}

run_no_trace() {
    [[ -z "${SW_ELF}" ]] && (echo "Missing argument"; exit 1;)
    cd run
	../${SIMULATOR_EXE} --meminit=ram,${SW_ELF} +ibex_tracer_enable=0
	cd -
}

wave() {
    gtkwave run/sim.fst
}

compile_tests(){
    for i in "${tests[@]}"; do
        echo "COMPILING --- $i"
        cd ./sw/binconv-"$i"/
        (make)
        cd -
    done
}

set_tests_config(){
    ([[ -z "$1" ]] || [[ -z "$2" ]]) && (echo "Missing argument"; exit 1;)
    sed -i "s/iw = .*/iw = $1/" $GEN_DATA_SCRIPT
    sed -i "s/ic = .*/ic = $2/" $GEN_DATA_SCRIPT
    $GEN_DATA_SCRIPT

    local path
    for i in "${tests[@]}"; do
        path="./sw/binconv-$i/binconv-$i.c"
        sed -i "s/uint32_t w_in = .*/uint32_t w_in = $1;/" $path
        sed -i "s/uint32_t h_in = .*/uint32_t h_in = $1;/" $path
        sed -i "s/uint32_t c_in = .*/uint32_t c_in = $2;/" $path
        sed -i "s/uint32_t c_out = .*/uint32_t c_out = $2;/" $path
    done
    
    compile_tests
}


 

execute_tests(){
    for i in "${tests[@]}"; do
        cycles="$( ./make.sh run_no_trace $i | grep "Cycles:" | awk '{print $2}' )"; 
        echo "$i: $cycles";  
    done
}

test(){
    execute_tests | column -t
}


$1 ${@:2}

exit 0

w=(56 28 14 7)
wp=(58 30 16 9)
c=(64 128 256 512)
for i in $(seq 0 $(( ${#w[@]}-1 ))); do
    echo ${wp[i]}
    ./make.sh set_tests_config ${wp[i]} ${c[i]} 1>/dev/null 2>/dev/null
    ./make.sh test
done