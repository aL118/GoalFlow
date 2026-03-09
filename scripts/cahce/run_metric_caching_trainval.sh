export NAVSIM_DEVKIT_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export OPENSCENE_DATA_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset
export NAVSIM_EXP_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export NUPLAN_MAPS_ROOT=/fs/nexus-projects/sim2real/aliu/navsim/dataset/maps
SPLIT=trainval
SCNEE_FILTER=navtrain_partial
CACHE_TO_SAVE=$NAVSIM_DEVKIT_ROOT/metric_cache_trainval #set your metric cache path to save

python $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_metric_caching.py \
scene_filter=$SCNEE_FILTER \
split=$SPLIT \
cache.cache_path=$CACHE_TO_SAVE \
scene_filter.frame_interval=1 \
