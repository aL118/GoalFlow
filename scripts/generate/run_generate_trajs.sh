#!/bin/bash

#SBATCH --job-name=goalflow_gen
#SBATCH --output=/fs/nexus-projects/sim2real/aliu/GoalFlow/logs/%x.out.%j
#SBATCH --error=/fs/nexus-projects/sim2real/aliu/GoalFlow/logs/%x.out.%j

## Scale ntasks with gpus
#SBATCH --mem=120gb                                               # memory required by job; if unit is not specified MB will be assumed
#SBATCH --gres=gpu:rtxa5000:8
#SBATCH --ntasks=32

## GAMMA training config
#SBATCH --time=60:00:00     
#SBATCH --qos=huge-long                                    
#SBATCH --account=gamma
#SBATCH --partition=gamma

# Load conda environment
source ~/.bashrc
conda activate goalflow

# Add conda lib to LD_LIBRARY_PATH for CUDA libraries
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/fs/nexus-scratch/aliu1237/miniconda3/envs/goalflow/lib
# export CUDA_VISIBLE_DEVICES=0,5 # 1,2,3,4
# export HYDRA_FULL_ERROR=1
export NAVSIM_DEVKIT_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export OPENSCENE_DATA_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset
export NAVSIM_EXP_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export NUPLAN_MAPS_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset/maps

FEATURE_CACHE=$NAVSIM_DEVKIT_ROOT/cache/dataset_cache_test # set your feature_cache path
VOC_PATH=$NAVSIM_DEVKIT_ROOT/data/cluster_points_8192_.npy
CHECKPOINT_PATH=$NAVSIM_DEVKIT_ROOT/data/goalflow_traj_epoch_54-step_18260.ckpt
GOAL_POINT_SCORES=$NAVSIM_DEVKIT_ROOT/data/goal_point_scores

NUM_GPUS=$(nvidia-smi --list-gpus | wc -l)
echo "Number of GPUs: $NUM_GPUS"
echo "Starting trajectory generation at $(date)"
echo "Using GPUs: $CUDA_VISIBLE_DEVICES"

CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 torchrun --nnodes=1 --nproc_per_node=8 --max_restarts=1 --rdzv_id=$SLURM_JOB_ID --rdzv_backend=c10d \
$NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_generate_trajs.py \
agent=goalflow_agent_traj \
experiment_name=a_test_release \
scene_filter=navtest \
split=test \
cache_path=$FEATURE_CACHE \
scene_filter.num_future_frames=10 \
dataloader.params.batch_size=4 \
use_cache_without_dataset=True \
agent.config.score_path=$GOAL_POINT_SCORES \
agent.config.voc_path=$VOC_PATH \
agent.config.generate='trajectory' \
agent.config.topk=15 \
agent.config.fusion=True \
agent.config.beta=0.0 \
agent.config.cond_threshold=1.0 \
agent.config.cond_weight=1.0 \
agent.config.training=False \
agent.config.has_navi=False \
agent.config.has_student_navi=True \
agent.config.start=True \
agent.config.cur_sampling=True \
agent.config.use_nearest=True \
agent.config.train_scale=0.1 \
agent.config.test_scale=0.1 \
agent.config.theta=4.5 \
agent.config.ep_score_weight=0.2 \
agent.config.ep_point_weight=0.5 \
agent.config.tf_d_model=1024 \
agent.config.infer_steps=5 \
agent.config.anchor_size=384 \
agent.checkpoint_path=$CHECKPOINT_PATH

echo "Finished trajectory generation at $(date)"