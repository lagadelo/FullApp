#!/usr/bin/env python3
# plot_results.py
# Usage: python plot_results.py results.csv

import sys
import csv
import matplotlib.pyplot as plt

if len(sys.argv) < 2:
    print("Usage: python plot_results.py results.csv")
    sys.exit(1)

csvfile = sys.argv[1]
ratios = []
allies = []
hostiles = []
coverage = []

with open(csvfile, newline='') as f:
    reader = csv.DictReader(f)
    for row in reader:
        ratios.append(float(row['ratio']))
        allies.append(int(row['alliesRemaining']))
        hostiles.append(int(row['hostilesRemaining']))
        try:
            coverage.append(float(row['coverageSize']))
        except:
            coverage.append(0.0)

# Plot survivors (allies & hostiles) as grouped bars, coverage as line
x = range(len(ratios))
width = 0.35

fig, ax1 = plt.subplots(figsize=(8,5))
ax1.bar([i - width/2 for i in x], allies, width, label='Allies remaining', align='center', color='tab:green')
ax1.bar([i + width/2 for i in x], hostiles, width, label='Hostiles remaining', align='center', color='tab:red')
ax1.set_xlabel('Ratio (surveillance fraction)')
ax1.set_xticks(x)
ax1.set_xticklabels([str(r) for r in ratios])
ax1.set_ylabel('Drones remaining')
ax1.legend(loc='upper left')

ax2 = ax1.twinx()
ax2.plot(x, coverage, label='Coverage size', color='tab:blue', marker='o')
ax2.set_ylabel('Coverage size (points or area metric)')
ax2.legend(loc='upper right')

plt.title('Scenario results comparison')
plt.tight_layout()
plt.show()

