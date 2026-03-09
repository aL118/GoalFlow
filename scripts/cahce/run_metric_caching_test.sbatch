#!/bin/bash
#SBATCH --job-name=metric_cache_test
#SBATCH --output=logs/metric_cache_test_%j.out
#SBATCH --error=logs/metric_cache_test_%j.err
#SBATCH --time=48:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=32
#SBATCH --nodes=1

export NAVSIM_DEVKIT_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export OPENSCENE_DATA_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset
export NAVSIM_EXP_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export NUPLAN_MAPS_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset/maps
SPLIT=test
SCNEE_FILTER=navtest_partial
CACHE_TO_SAVE=$NAVSIM_DEVKIT_ROOT/metric_cache_test

python $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_metric_caching.py \
scene_filter=$SCNEE_FILTER \
split=$SPLIT \
cache.cache_path=$CACHE_TO_SAVE \
scene_filter.frame_interval=1
