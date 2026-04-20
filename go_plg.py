import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import pingouin as pg
from scipy import stats
import numpy as np

def cousineau_morey_ci(df, subject_col, condition_col, value_col, confidence=0.95):
    """
    implements the Cousineau-Morey method for computing 95% CIs for
    a repeated measures design
    """
    subject_means = df.groupby(subject_col)[value_col].transform('mean')
    grand_mean = df[value_col].mean()
    df['normalized_val'] = df[value_col] - subject_means + grand_mean
    c = df[condition_col].nunique()
    n = df[subject_col].nunique()
    correction_factor = np.sqrt(c / (c - 1))
    results = df.groupby(condition_col)['normalized_val'].agg(['mean', 'std']).reset_index()
    results['se'] = results['std'] / np.sqrt(n)
    results['se_adj'] = results['se'] * correction_factor
    t_val = stats.t.ppf((1 + confidence) / 2, n - 1)
    results['ci_half_width'] = t_val * results['se_adj']
    return results[[condition_col, 'mean', 'se_adj', 'ci_half_width']]


d = pd.read_csv("MeanP2adaptersno9_long.csv")
d = d[d["Bin"] <= 6].copy()
d["Participant"] = d["Participant"].astype(str)
d["Bin"] = d["Bin"].astype(int)

# Plot 1: individual participant trajectories
fig, ax = plt.subplots(figsize=(4, 4))
sns.lineplot(data=d, x="Bin", y="MeanERP", hue="Participant",
             marker="o", ax=ax, legend=False)
ax.set_xlabel("Bin")
ax.set_ylabel("Mean ERP")
ax.set_xlim([0.5, 6.5])
ax.set_ylim([0.5, 8])
sns.despine()
ax.spines['bottom'].set_bounds(1,6)
ax.spines['left'].set_bounds(1,8)
plt.tight_layout()
fname = "plot1_individual_trajectories.png"
print(f"saving plot to {fname}")
plt.savefig(fname, dpi=150)
plt.close()

# Plot 2: group mean +/- 95% within-subject CI (Cousineau-Morey)
bin_means = cousineau_morey_ci(d, 'Participant', 'Bin', 'MeanERP')

fig, ax = plt.subplots(figsize=(4, 4))
ax.errorbar(bin_means["Bin"], bin_means["mean"],
            yerr=bin_means["ci_half_width"], fmt="o-", color="black",
            capsize=4, linewidth=1.5)
ax.set_xlabel("Bin")
ax.set_ylabel("Mean ERP")
ax.set_ylim([2.5, 7])
ax.set_yticks([3, 4, 5, 6])
ax.set_xlim([0.5, 6.5])
sns.despine()
ax.spines['bottom'].set_bounds(1,6)
ax.spines['left'].set_bounds(3,6)
plt.tight_layout()
fname = "plot2_group_mean_ci.png"
print(f"saving plot to {fname}")
plt.savefig(fname, dpi=150)
plt.close()

# Repeated-measures ANOVA: MeanERP ~ Bin (within subjects)
aov = pg.rm_anova(data=d, dv="MeanERP", within="Bin", subject="Participant", detailed=True)

# Post-hoc pairwise paired t-tests with Holm correction
posthoc = pg.pairwise_tests(data=d, dv="MeanERP", within="Bin",
                             subject="Participant", padjust="holm")

with open("stats.txt", "w") as f:
    f.write("Repeated Measures ANOVA\n")
    f.write("-"*25 + "\n")
    f.write(aov.to_string() + "\n")
    f.write("\nPost-hoc Pairwise Tests:\n")
    f.write("-"*25 + "\n")
    f.write(posthoc[["A", "B", "T", "dof", "p_unc", "p_corr", "p_adjust"]].to_string() + "\n")
print("stats written to stats.txt")
