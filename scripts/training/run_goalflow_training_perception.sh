#!/bin/bash

# Define a base name for the job, experiment, and output files

#SBATCH --job-name=test                            
#SBATCH --output=/fs/nexus-projects/sim2real/aliu/GoalFlow/scripts/training/logs/%x.out.%j
#SBATCH --error=/fs/nexus-projects/sim2real/aliu/GoalFlow/scripts/training/logs/%x.out.%j

## Scale ntasks with gpus
#SBATCH --mem=120gb                                               # memory required by job; if unit is not specified MB will be assumed
#SBATCH --gres=gpu:rtxa6000:4
#SBATCH --ntasks=16

## GAMMA training config
#SBATCH --time=40:00:00     
#SBATCH --qos=huge-long                                    
#SBATCH --account=gamma
#SBATCH --partition=gamma

conda activate goalflow

export NAVSIM_DEVKIT_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export OPENSCENE_DATA_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset
export NAVSIM_EXP_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export NUPLAN_MAPS_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset/maps

FEATURE_CACHE=$NAVSIM_DEVKIT_ROOT/cache/dataset_cache_trainval # set your feature_cache path
V99_PRETRAINED_PATH=$NAVSIM_DEVKIT_ROOT/data/depth_pretrained_v99-3jlw0p36-20210423_010520-model_final-remapped.pth
CHECKPOINT_PATH='/fs/nexus-projects/sim2real/aliu/GoalFlow/a_train_traj/2026.01.03.11.35.58/lightning_logs/version_6002809/checkpoints/epoch\=14-step\=223995.ckpt' # Resume from epoch 14
VOC_PATH=$NAVSIM_DEVKIT_ROOT/data/cluster_points_8192_.npy
ONLY_PERCEPTION=True
FREEZE_PERCEPTION=False # you can choose False and increase batch_size if the GPU are sufficient

# Add conda lib to LD_LIBRARY_PATH for CUDA libraries
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/fs/nexus-scratch/aliu1237/miniconda3/envs/goalflow/lib

# Disable SM80-specific CUDA kernels for RTX A5000 compatibility
export TORCH_CUDNN_SDPA_ENABLED=0
export PYTORCH_ENABLE_MPS_FALLBACK=1
# Force PyTorch to use math attention instead of flash attention
export TORCH_CUDNN_V8_API_ENABLED=0
# Disable cuDNN benchmarking which may select incompatible kernels
export CUDNN_BENCHMARK=0
# Force attention to use slower but compatible implementation
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export HYDRA_FULL_ERROR=1
CUDA_VISIBLE_DEVICES=0,1,2,3 torchrun --nnodes=1 --nproc_per_node=4 --max_restarts=1 --rdzv_id=$SLURM_JOB_ID --rdzv_backend=c10d \
$NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_training.py \
agent=goalflow_agent_traj \
experiment_name=a_train_traj \
scene_filter=navtrain_partial \
split=trainval \
cache_path="$FEATURE_CACHE" \
trainer.params.max_epochs=100 \
trainer.params.precision=16-mixed \
trainer.params.gradient_clip_val=1.0 \
agent.config.training=true \
agent.config.has_navi=true \
agent.config.start=true \
agent.config.freeze_perception=false \
agent.config.only_perception=true \
agent.config.train_scale=0.1 \
agent.config.tf_d_model=1024 \
agent.config.trajectory_weight=0.0 \
agent.config.agent_class_weight=10.0 \
agent.config.agent_box_weight=1.0 \
agent.config.bev_semantic_weight=10.0 \
agent.config.agent_loss=true \
dataloader.params.batch_size=2 \
use_cache_without_dataset=true \
agent.config.v99_pretrained_path="$V99_PRETRAINED_PATH" \
agent.checkpoint_path="$CHECKPOINT_PATH" \
agent.config.voc_path="$VOC_PATH"