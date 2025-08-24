#!/bin/bash

#SBATCH --job-name=alphafold3-inference
#SBATCH --account=def-someprof
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=1
#SBATCH --gpus=a100:1
#SBATCH --mem=20G
### Need to change the next one to 0 - n-1, n=number of json files ###
#SBATCH --array=0-202

# Load required modules
module load StdEnv/2023 hmmer/3.4 rdkit/2024.03.5 python/3.12 cuda/12 cudnn/9.2

# Define base directories
### NEEDS TO CHANGE TO MATCH THE PREVIOUS JOB. Line 18 needs to match with Line 58 ###
DOWNLOAD_DIR=$SCRATCH/alphafold/dbs
INPUT_BASE=$SCRATCH/alphafold/output
OUTPUT_BASE=$SCRATCH/alphafold/inference_outputs
MODEL_DIR=$SCRATCH/alphafold/model_weights

# Resolve input/output for this task
TASK_DIR=${INPUT_BASE}/task_${SLURM_ARRAY_TASK_ID}
OUTPUT_DIR=${OUTPUT_BASE}/task_${SLURM_ARRAY_TASK_ID}

# Create and activate virtual environment
virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate

# Install dependencies
pip install --no-index --upgrade pip
pip install --no-index --requirement ~/alphafold3-requirements.txt

# Prepare data converters
build_data

# Set XLA environment flags
export XLA_FLAGS="--xla_gpu_enable_triton_gemm=false"
export XLA_PYTHON_CLIENT_PREALLOCATE=true
export XLA_CLIENT_MEM_FRACTION=0.95

# Find the actual JSON input path
INPUT_JSON=$(find "$TASK_DIR" -name "*_data.json" | head -n 1)

# Safety check: warn if no JSON was found
if [ -z "$INPUT_JSON" ]; then
  echo "ERROR: No input JSON found in $TASK_DIR"
  exit 1
fi

### NEED TO CHANGE THIS, I THINK YOU NEED TO BE CAREFUL WITH LINE 19, BUT I AM TOO SCARED TO CHANGE ANYTHING###
OUTPUT_DIR=$SCRATCH/alphafold/inference_outputs/task_$SLURM_ARRAY_TASK_ID
mkdir -p "$OUTPUT_DIR"

# Run AlphaFold3
python /home/user/run_alphafold.py \
    --db_dir=$DOWNLOAD_DIR \
    --input_dir=$(dirname "$INPUT_JSON") \
    --output_dir=$OUTPUT_DIR \
    --jax_compilation_cache_dir=$HOME/.cache \
    --norun_data_pipeline \
    --model_dir=$MODEL_DIR
