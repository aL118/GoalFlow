# export LD_LIBRARY_PATH="/usr/local/cuda/lib64"
# export HYDRA_FULL_ERROR=1
export NAVSIM_DEVKIT_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export OPENSCENE_DATA_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset
export NAVSIM_EXP_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export NUPLAN_MAPS_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset/maps

SPLIT=test
METRIC_CACHE=$NAVSIM_DEVKIT_ROOT/metric_cache_test # set your metric path 
TRAJS_CACHE=$NAVSIM_DEVKIT_ROOT/a_test_release/2025.12.26.22.48.09/lightning_logs/version_5982384/trajs # set your trajectories path

python $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_pdm_score_trajs.py \
agent=goalflow_agent_traj \
agent.checkpoint_path=$CHECKPOINT \
experiment_name=a_test_release_result \
scene_filter=navtest \
split=$SPLIT \
metric_cache_path=$METRIC_CACHE \
trajs_cache_path=$TRAJS_CACHE \