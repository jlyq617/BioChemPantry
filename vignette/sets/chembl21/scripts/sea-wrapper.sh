#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N search-sea

### This is a SGE submission script to screen targets against a library.
###
###   Directories and files used by thi script
###     <run_base>/
###        inputs/
###          <target_id>.csv   # with column headers (compound, smiles)
###        logs/
###        outputs/
###        sea-wrapper.sh
###     /scratch/$(whoami)/
###        <job_id>/<job_id>/<task_name>
###
###     <library_fname> # .sea library
###  
###   To submit job
###     cd <run_base>/logs
###     qsub -t 1-<n_targets> ../sea-wrapper.sh <run_base> <library_fname> <fp_type>
###     


shopt -s nullglob
set -e

PERSIST=$1
SEA_CONFIG_FILES=($PERSIST/*.cfg)

LIB_FULL=$2
LIB=$(basename $LIB_FULL)

FP_TYPE=$3

INPUT_FILES=$PERSIST/inputs
COMPLETE=$PERSIST/outputs
TASK_INPUT=$( ls $INPUT_FILES | sed -n ${SGE_TASK_ID}p )
TASK_NAME=$( basename ${TASK_INPUT%.*} )
TASK_FILE=$INPUT_FILES/$TASK_INPUT

SCRATCH_DIR=/scratch
if [ ! -d $SCRATCH_DIR ]; then
    SCRATCH_DIR=/tmp
fi

TASK_DIR=$SCRATCH_DIR/$( whoami )/$JOB_ID/$TASK_NAME

cmd="SeaShell.py \
    batch \
    --library $LIB \
    --disable-precache \
    --skip-standardization \
    --target-name $TASK_NAME \
    --generate-fingerprint $FP_TYPE \
    $TASK_FILE \
    $TASK_INPUT.out.csv 1>&2"


echo "SGE_TASK_ID:" $SGE_TASK_ID 1>&2
echo "Source file:" $TASK_FILE 1>&2
echo "Run dir:" $( hostname ):$TASK_DIR 1>&2
echo "SEA library:" $LIB_FULL 1>&2
echo "fingerprint type:" $FP_TYPE 1>&2
echo "config_files:" $SEA_CONFIG_FILES 1>&2
echo "cmd:" $cmd 1>&2

source /nfs/work/momeara/tools/anaconda2/envs/sea16/bin/activate sea16

mkdir -pv $TASK_DIR 1>&2
pushd $TASK_DIR 1>&2

cp $LIB_FULL .

for $SEA_CONFIG_FILE in $SEA_CONFIG_FILES; do
    cp $SEA_CONFIG_FILE .
done

eval $cmd
/bin/rm -f $LIB*

popd
mkdir -pv $COMPLETE 1>&2
mv -v $TASK_DIR $COMPLETE/$TASK_NAME 1>&2
rm -rvf $TASK_DIR 1>&2
