#!/bin/bash

wsm="./opt.wasm"
wsm="./fcnt.wasm"

i32le2human(){
  imports='import sys; import functools; import operator; import struct;'

  cat /dev/stdin |
    python3 -c "${imports}"'functools.reduce(
      lambda state, f: f(state),
      [
        struct.Struct("<i").unpack,
        operator.itemgetter(0),
        print,
      ],
      sys.stdin.buffer.read(4),
    )'
}

nodir(){
  wasmtime run "${wsm}" | i32le2human
}

single(){
  wasmtime run --dir . "${wsm}" | i32le2human
}

multi(){
  wasmtime run \
    --dir . \
    --dir .. \
    "${wsm}" |
    i32le2human
}

echo no dir
nodir
echo

echo single dir
single
echo

echo multi dirs
multi
echo
