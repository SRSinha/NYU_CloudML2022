#!/bin/bash

python3 mainFullProfiler.py --epochs 1 --batch-size 1   #need warmup
python3 mainFullProfiler.py --epochs 1 --batch-size 1 |& tee OP_FULL/main_full_batch1.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 16 |& tee OP_FULL/main_full_batch16.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 32 |& tee OP_FULL/main_full_batch32.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 60 |& tee OP_FULL/main_full_batch60.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 64 |& tee OP_FULL/main_full_batch64.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 68 |& tee OP_FULL/main_full_batch68.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 128 |& tee OP_FULL/main_full_batch128.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 256 |& tee OP_FULL/main_full_batch256.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 512 |& tee OP_FULL/main_full_batch512.txt
python3 mainFullProfiler.py --epochs 1 --batch-size 1024 |& tee OP_FULL/main_full_batch1024.txt
