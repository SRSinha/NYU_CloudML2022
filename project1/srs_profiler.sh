#!/bin/bash
if [ -z $1 ]
then
        echo "Forgot to add the architecture? Try again"
        exit 1
fi
ARCH=$1

export PATH=$PATH:/share/apps/cuda/11.1.74/bin
CMD="python3 main.py /imagenet/ --arch $ARCH --epochs 1"
# METRICS="dram__bytes_write.sum,dram__bytes_read.sum,smsp__sass_thread_inst_executed_op_fadd_pred_on.sum,smsp__sass_thread_inst_executed_op_fmul_pred_on.sum,smsp__sass_thread_inst_executed_op_ffma_pred_on.sum"
METRICS="dram__sectors_read.sum,dram__sectors_write.sum,dram__bytes_write.sum,dram__bytes_read.sum,smsp__sass_thread_inst_executed_op_fadd_pred_on.sum,smsp__sass_thread_inst_executed_op_fmul_pred_on.sum,smsp__sass_thread_inst_executed_op_ffma_pred_on.sum,smsp__sass_thread_inst_executed_op_dadd_pred_on.sum,smsp__sass_thread_inst_executed_op_dfma_pred_on.sum,smsp__sass_thread_inst_executed_op_dmul_pred_on.sum,smsp__sass_thread_inst_executed_op_hadd_pred_on.sum,smsp__sass_thread_inst_executed_op_hfma_pred_on.sum,smsp__sass_thread_inst_executed_op_hmul_pred_on.sum"

# ncu files
rm -rf $ARCH
mkdir $ARCH
NCU_RAW_LOG="$ARCH/ncu-runtime-$ARCH.log"
NCU_METRICS_LOG="$ARCH/ncu-metric-$ARCH.log"
rm -rf NCU_METRICS_LOG

# nsys file
NSYS_RAW_LOG="$ARCH/nsys-runtime-$ARCH.qdrep"
NSYS_METRICS_LOG="$ARCH/nsys-metric-$ARCH.log"
rm -rf NSYS_RAW_LOG NSYS_METRICS_LOG

echo "********** NCU PROFILING STARTS **********"
# run ncu
/share/apps/cuda/11.1.74/bin/ncu -f --log-file $NCU_RAW_LOG --metrics $METRICS --target-processes all $CMD
# compute bytes
BYTES=`cat $NCU_RAW_LOG | grep -e "dram__bytes_write.sum" -e "dram__bytes_read.sum" | grep -e " byte" | sed -e "s/,/ /g" | awk '{print($3)}' | paste -sd+ | bc`
KBYTES=`cat $NCU_RAW_LOG | grep -e "dram__bytes_write.sum" -e "dram__bytes_read.sum" | grep -e "Kbyte" | sed -e "s/,/ /g"  |awk '{print($3)}' | paste -sd+ | bc`
MBYTES=`cat $NCU_RAW_LOG | grep -e "dram__bytes_write.sum" -e "dram__bytes_read.sum" | grep -e "Mbyte" | sed -e "s/,/ /g" | awk '{print($3)}' | paste -sd+ | bc`
GBYTES=`cat $NCU_RAW_LOG | grep -e "dram__bytes_write.sum" -e "dram__bytes_read.sum" | grep -e "Gbyte" | sed -e "s/,/ /g" | awk '{print($3)}' | paste -sd+ | bc`
TOTAL_BYTES=`awk "BEGIN{ print $BYTES + 1000*$KBYTES + 1000000*$MBYTES + 1000000000*$GBYTES }"`
echo "TOTALBYTES" >> $NCU_METRICS_LOG
echo $TOTAL_BYTES >> $NCU_METRICS_LOG


DW=`cat $NCU_RAW_LOG | grep -e "dram__sectors_write.sum" | sed -e "s/,/ /g" |   awk '{print($3)}' | paste -sd+ | bc`
DR=`cat $NCU_RAW_LOG | grep -e "dram__sectors_read.sum" | sed -e "s/,/ /g" |  awk '{print($3)}' | paste -sd+ | bc`
echo $'\nDRDW TRANSACTIONS' >> $NCU_METRICS_LOG
TTXNS=$((DW + DR))
echo $TTXNS >> $NCU_METRICS_LOG

#compute FLOPS
TMP1=`cat $NCU_RAW_LOG | grep -e "smsp__sass_thread_inst_executed_op_fadd_pred_on.sum" -e  "smsp__sass_thread_inst_executed_op_fmul_pred_on.sum" | sed -e "s/,/ /g" | awk '{print $3}' | paste -sd+ | bc`
TMP2=`cat $NCU_RAW_LOG | grep -e "smsp__sass_thread_inst_executed_op_ffma_pred_on.sum" | sed -e "s/,/ /g" | awk '{print $3}' | paste -sd+ | bc`
SINGLEFLOPS=$((TMP1 + 2*TMP2))
echo $'\nSINGLEFLOPS' >> $NCU_METRICS_LOG
echo $SINGLEFLOPS >> $NCU_METRICS_LOG

TMP3=`cat $NCU_RAW_LOG | grep -e "smsp__sass_thread_inst_executed_op_dadd_pred_on.sum" -e  "smsp__sass_thread_inst_executed_op_dmul_pred_on.sum" | sed -e "s/,/ /g" | awk '{print $3}' | paste -sd+ | bc`
TMP4=`cat $NCU_RAW_LOG | grep -e "smsp__sass_thread_inst_executed_op_dfma_pred_on.sum" | sed -e "s/,/ /g" | awk '{print $3}' | paste -sd+ | bc`
DOUBLEFLOPS=$((TMP3 + 2*TMP4))
echo "DOUBLEFLOPS" >> $NCU_METRICS_LOG
echo $DOUBLEFLOPS >> $NCU_METRICS_LOG

TMP5=`cat $NCU_RAW_LOG | grep -e "smsp__sass_thread_inst_executed_op_hadd_pred_on.sum" -e  "smsp__sass_thread_inst_executed_op_hmul_pred_on.sum" | sed -e "s/,/ /g" | awk '{print $3}' | paste -sd+ | bc`
TMP6=`cat $NCU_RAW_LOG | grep -e "smsp__sass_thread_inst_executed_op_hfma_pred_on.sum" | sed -e "s/,/ /g" | awk '{print $3}' | paste -sd+ | bc`
HALFFLOPS=$((TMP5 + 2*TMP6))
echo "HALFFLOPS" >> $NCU_METRICS_LOG
echo $HALFFLOPS >> $NCU_METRICS_LOG

TFLOPS=$((TMP1 + 2*TMP2 + TMP3 + 2*TMP4 + TMP5 + 2*TMP6))
echo "TOTALFLOPS" >> $NCU_METRICS_LOG
echo $TFLOPS >> $NCU_METRICS_LOG

echo $'********** NCU PROFILING ENDED **********\n'



echo "********** NSYS PROFILING STARTS **********"
nsys profile -f true -o $NSYS_RAW_LOG $CMD
rm -rf $ARCH/tmp_nsys_gputrace.csv
nsys stats --report gputrace $NSYS_RAW_LOG -o $ARCH/tmp_nsys
# compute runtime
echo "Runtime(nanosec)" >> $NSYS_METRICS_LOG
tail -n +2 $ARCH/tmp_nsys_gputrace.csv | sed -e "s/,/ /g" | awk '{print $2}' | paste -sd+ | bc >> $NSYS_METRICS_LOG
echo "********** NSYS PROFILING ENDED **********"
