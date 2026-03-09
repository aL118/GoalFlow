# LD_LIBRARY_PATH="/usr/local/cuda/lib64"
# export CUDA_VISIBLE_DEVICES=2
# TODO: if need to run, change this script to sbatch script
export NAVSIM_DEVKIT_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export OPENSCENE_DATA_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset
export NAVSIM_EXP_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export NUPLAN_MAPS_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset/maps

FEATURE_CACHE=$NAVSIM_DEVKIT_ROOT/cache/dataset_cache_test
VOC_PATH=$NAVSIM_DEVKIT_ROOT/data/cluster_points_8192_.npy
CHECKPOINT_PATH=$NAVSIM_DEVKIT_ROOT/data/goalflow_navi_epoch_99-step_132500.ckpt

python $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_generate_trajs.py \
agent=goalflow_agent_navi \
experiment_name=a_test_release_navi \
scene_filter=navtest \
split=test \
cache_path=$FEATURE_CACHE \
agent.config.generate='goal_score' \
agent.config.voc_path=$VOC_PATH \
agent.config.training=False \
agent.config.tf_d_model=1024 \
dataloader.params.batch_size=4 \
use_cache_without_dataset=True \
agent.checkpoint_path=$CHECKPOINT_PATH