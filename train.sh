#!/bin/bash

################################################################################
# GoalFlow Training Script
#
# This script trains the GoalFlow model in three stages:
#   1. Perception Module
#   2. Trajectory Planning Module
#   3. Goal Point Construction Module (Optional)
#
# Usage:
#   ./train.sh [stage]
#
# Examples:
#   ./train.sh perception    # Train perception module
#   ./train.sh trajectory    # Train trajectory planning module
#   ./train.sh navigation    # Train goal point construction module
#   ./train.sh               # Interactive mode - asks which stage
################################################################################

set -e  # Exit on error

# ============================================================================
# CONFIGURATION - Edit these paths before running
# ============================================================================

# Data paths
export NAVSIM_DEVKIT_ROOT=/fs/nexus-projects/sim2real/aliu/GoalFlow
export OPENSCENE_DATA_ROOT="${OPENSCENE_DATA_ROOT:-/path/to/navsim/data}"  # TODO: Set your data path
export NAVSIM_EXP_ROOT="${NAVSIM_EXP_ROOT:-$NAVSIM_DEVKIT_ROOT/experiments}"  # Where to save experiments

# Model paths - Update these with your actual paths
FEATURE_CACHE="${FEATURE_CACHE:-$NAVSIM_EXP_ROOT/training_cache_trainval}"
V99_PRETRAINED_PATH="${V99_PRETRAINED_PATH:-$NAVSIM_DEVKIT_ROOT/data/depth_pretrained_v99-3jlw0p36-20210423_010520-model_final-remapped.pth}"
VOC_PATH="${VOC_PATH:-$NAVSIM_DEVKIT_ROOT/data/cluster_points_8192_.npy}"

# Checkpoint paths (updated after each stage)
PERCEPTION_CHECKPOINT="${PERCEPTION_CHECKPOINT:-}"  # Leave empty for first run
TRAJECTORY_CHECKPOINT="${TRAJECTORY_CHECKPOINT:-$NAVSIM_DEVKIT_ROOT/data/goalflow_traj_epoch_54-step_18260.ckpt}"

# Training parameters
MAX_EPOCHS="${MAX_EPOCHS:-100}"
BATCH_SIZE="${BATCH_SIZE:-2}"
NUM_GPUS="${NUM_GPUS:-8}"

# Optional: Uncomment to use specific GPUs
# export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

# Optional: Enable detailed Hydra error messages
# export HYDRA_FULL_ERROR=1

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

print_info() {
    echo "[INFO] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
    exit 1
}

check_path() {
    if [ ! -e "$2" ]; then
        print_warning "$1 not found at: $2"
        print_warning "Please update the path in this script or set the environment variable"
        return 1
    fi
    return 0
}

# ============================================================================
# Training Stage Functions
# ============================================================================

train_perception() {
    print_header "Stage 1: Training Perception Module"

    print_info "Configuration:"
    print_info "  - Experiment name: train_perception"
    print_info "  - Max epochs: $MAX_EPOCHS"
    print_info "  - Batch size: $BATCH_SIZE"
    print_info "  - Feature cache: $FEATURE_CACHE"
    print_info "  - V99 pretrained: $V99_PRETRAINED_PATH"

    # Check required files
    check_path "V99 pretrained weights" "$V99_PRETRAINED_PATH" || print_warning "You may need to download this first"

    python $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_training.py \
        agent=goalflow_agent_traj \
        experiment_name=train_perception \
        scene_filter=navtrain \
        split=trainval \
        cache_path=$FEATURE_CACHE \
        trainer.params.max_epochs=$MAX_EPOCHS \
        trainer.params.devices=$NUM_GPUS \
        agent.config.training=True \
        agent.config.has_navi=True \
        agent.config.start=True \
        agent.config.freeze_perception=False \
        agent.config.only_perception=True \
        agent.config.train_scale=0.1 \
        agent.config.tf_d_model=1024 \
        agent.config.trajectory_weight=0.0 \
        agent.config.agent_class_weight=10.0 \
        agent.config.agent_box_weight=1.0 \
        agent.config.bev_semantic_weight=10.0 \
        agent.config.agent_loss=True \
        dataloader.params.batch_size=$BATCH_SIZE \
        use_cache_without_dataset=True \
        agent.config.v99_pretrained_path=$V99_PRETRAINED_PATH \
        ${PERCEPTION_CHECKPOINT:+agent.checkpoint_path=$PERCEPTION_CHECKPOINT} \
        agent.config.voc_path=$VOC_PATH

    print_info "Perception module training complete!"
    print_info "Find your checkpoint in: $NAVSIM_EXP_ROOT/train_perception/<timestamp>/"
    print_info "Set PERCEPTION_CHECKPOINT to this path before running trajectory training"
}

train_trajectory() {
    print_header "Stage 2: Training Trajectory Planning Module"

    print_info "Configuration:"
    print_info "  - Experiment name: train_trajectory"
    print_info "  - Max epochs: $MAX_EPOCHS"
    print_info "  - Batch size: $BATCH_SIZE"
    print_info "  - Freeze perception: True (faster training)"
    print_info "  - Checkpoint: ${TRAJECTORY_CHECKPOINT:-None}"

    # Check required files
    if [ -z "$TRAJECTORY_CHECKPOINT" ]; then
        print_warning "No checkpoint specified. Training from scratch (requires perception checkpoint)"
    fi

    python $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_training.py \
        agent=goalflow_agent_traj \
        experiment_name=train_trajectory \
        scene_filter=navtrain \
        split=trainval \
        cache_path=$FEATURE_CACHE \
        trainer.params.max_epochs=$MAX_EPOCHS \
        trainer.params.devices=$NUM_GPUS \
        agent.config.training=True \
        agent.config.has_navi=True \
        agent.config.start=True \
        agent.config.freeze_perception=True \
        agent.config.only_perception=False \
        agent.config.train_scale=0.1 \
        agent.config.tf_d_model=1024 \
        agent.config.trajectory_weight=50.0 \
        agent.config.agent_class_weight=0.2 \
        agent.config.agent_box_weight=0.05 \
        agent.config.bev_semantic_weight=0.2 \
        agent.config.agent_loss=True \
        dataloader.params.batch_size=$BATCH_SIZE \
        use_cache_without_dataset=True \
        agent.config.v99_pretrained_path=$V99_PRETRAINED_PATH \
        ${TRAJECTORY_CHECKPOINT:+agent.checkpoint_path=$TRAJECTORY_CHECKPOINT} \
        agent.config.voc_path=$VOC_PATH

    print_info "Trajectory planning module training complete!"
    print_info "Find your checkpoint in: $NAVSIM_EXP_ROOT/train_trajectory/<timestamp>/"
}

train_navigation() {
    print_header "Stage 3: Training Goal Point Construction Module (Optional)"

    print_info "Configuration:"
    print_info "  - Experiment name: train_navigation"
    print_info "  - Max epochs: $MAX_EPOCHS"
    print_info "  - Batch size: $BATCH_SIZE"
    print_info "  - Freeze perception: True (faster training)"

    if [ -z "$TRAJECTORY_CHECKPOINT" ]; then
        print_error "TRAJECTORY_CHECKPOINT must be set for navigation training"
    fi

    python $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_training.py \
        agent=goalflow_agent_navi \
        experiment_name=train_navigation \
        scene_filter=navtrain \
        split=trainval \
        cache_path=$FEATURE_CACHE \
        trainer.params.max_epochs=$MAX_EPOCHS \
        trainer.params.devices=$NUM_GPUS \
        agent.config.training=True \
        agent.config.has_navi=True \
        agent.config.start=True \
        agent.config.freeze_perception=True \
        dataloader.params.batch_size=$BATCH_SIZE \
        use_cache_without_dataset=True \
        agent.config.v99_pretrained_path=$V99_PRETRAINED_PATH \
        agent.checkpoint_path=$TRAJECTORY_CHECKPOINT \
        agent.config.voc_path=$VOC_PATH

    print_info "Goal point construction module training complete!"
    print_info "Find your checkpoint in: $NAVSIM_EXP_ROOT/train_navigation/<timestamp>/"
}

# ============================================================================
# Interactive Mode
# ============================================================================

interactive_mode() {
    print_header "GoalFlow Training - Interactive Mode"

    echo "Select training stage:"
    echo "  1) Perception Module (Stage 1)"
    echo "  2) Trajectory Planning Module (Stage 2)"
    echo "  3) Goal Point Construction Module (Stage 3 - Optional)"
    echo "  4) Exit"
    echo ""
    read -p "Enter choice [1-4]: " choice

    case $choice in
        1) train_perception ;;
        2) train_trajectory ;;
        3) train_navigation ;;
        4) exit 0 ;;
        *) print_error "Invalid choice" ;;
    esac
}

# ============================================================================
# Main Script
# ============================================================================

print_header "GoalFlow Training Script"

# Validate environment
print_info "Checking environment..."
print_info "NAVSIM_DEVKIT_ROOT: $NAVSIM_DEVKIT_ROOT"
print_info "OPENSCENE_DATA_ROOT: $OPENSCENE_DATA_ROOT"
print_info "NAVSIM_EXP_ROOT: $NAVSIM_EXP_ROOT"

if [ "$OPENSCENE_DATA_ROOT" = "/path/to/navsim/data" ]; then
    print_warning "OPENSCENE_DATA_ROOT is not set. Please update the script or set the environment variable."
fi

# Create experiment directory if it doesn't exist
mkdir -p "$NAVSIM_EXP_ROOT"

# Parse command line arguments
STAGE="${1:-}"

case $STAGE in
    perception|1)
        train_perception
        ;;
    trajectory|traj|2)
        train_trajectory
        ;;
    navigation|navi|goal|3)
        train_navigation
        ;;
    "")
        interactive_mode
        ;;
    *)
        print_error "Unknown stage: $STAGE. Use: perception, trajectory, or navigation"
        ;;
esac

print_header "Training Complete!"
