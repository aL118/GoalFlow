#!/usr/bin/env python3
"""
Calculate average metrics from NavSim evaluation results CSV file.
"""

import pandas as pd
import argparse
from pathlib import Path


def calculate_metrics(csv_path):
    """
    Calculate and print average metrics from evaluation results.

    Args:
        csv_path: Path to the CSV file containing evaluation results
    """
    print(f"Reading CSV file: {csv_path}")
    df = pd.read_csv(csv_path)

    print(f"Total number of scenarios: {len(df)}")

    # Filter only valid scenarios if 'valid' column exists
    if 'valid' in df.columns:
        valid_df = df[df['valid'] == True]
        print(f"Valid scenarios: {len(valid_df)}")
        invalid_count = len(df) - len(valid_df)
        if invalid_count > 0:
            print(f"Invalid scenarios: {invalid_count}")
    else:
        valid_df = df

    # Identify metric columns (exclude index, token, and valid columns)
    exclude_cols = ['token', 'valid']
    metric_cols = [col for col in valid_df.columns
                   if col not in exclude_cols and pd.api.types.is_numeric_dtype(valid_df[col])]

    # Remove the unnamed index column if it exists
    metric_cols = [col for col in metric_cols if not col.startswith('Unnamed')]

    print("\n" + "="*70)
    print("AVERAGE METRICS")
    print("="*70)

    # Calculate and display averages
    averages = {}
    for col in metric_cols:
        avg = valid_df[col].mean()
        averages[col] = avg
        print(f"{col:40s}: {avg:.6f}")

    print("="*70)

    return averages


def main():
    parser = argparse.ArgumentParser(
        description='Calculate average metrics from NavSim evaluation results CSV file.'
    )
    parser.add_argument(
        'csv_path',
        type=str,
        nargs='?',
        default='/fs/nexus-projects/sim2real/aliu/GoalFlow/a_test_release_result/2025.12.27.10.50.38/2025.12.27.10.54.40.csv',
        help='Path to the CSV file (default: latest test release result)'
    )

    args = parser.parse_args()

    csv_path = Path(args.csv_path)

    if not csv_path.exists():
        print(f"Error: CSV file not found: {csv_path}")
        return 1

    calculate_metrics(csv_path)
    return 0


if __name__ == '__main__':
    exit(main())

"""
Total number of scenarios: 1973
Valid scenarios: 1973

======================================================================
PRETRAINED METRICS
======================================================================
no_at_fault_collisions                  : 0.987069
drivable_area_compliance                : 0.987323
driving_direction_compliance            : 1.000000
ego_progress                            : 0.849019
time_to_collision_within_bound          : 0.953854
comfort                                 : 1.000000
score                                   : 0.908356
======================================================================
"""