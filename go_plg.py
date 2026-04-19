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
sns.despine()
plt.tight_layout()
fname = "plot1_individual_trajectories.png"
print(f"saving plot to {fname}")
plt.savefig(fname, dpi=150)
plt.close()

# Plot 2: group mean +/- 95% within-subject CI (Cousineau-Morey)
summary = cousineau_morey_ci(d, 'Participant', 'Bin', 'MeanERP')

fig, ax = plt.subplots(figsize=(4, 4))
ax.errorbar(summary["Bin"], summary["mean"],
            yerr=summary["ci_half_width"], fmt="o-", color="black",
            capsize=4, linewidth=1.5)
ax.set_xlabel("Bin")
ax.set_ylabel("Mean ERP")
ax.set_ylim([2, 7])
sns.despine()
plt.tight_layout()
fname = "plot2_group_mean_ci.png"
print(f"saving plot to {fname}")
plt.savefig(fname, dpi=150)
plt.close()

# Repeated-measures ANOVA: MeanERP ~ Bin (within subjects)
aov = pg.rm_anova(data=d, dv="MeanERP", within="Bin", subject="Participant", detailed=True)
print("\nRepeated Measures ANOVA")
print(aov.to_string())

# Post-hoc pairwise paired t-tests with Holm correction
posthoc = pg.pairwise_tests(data=d, dv="MeanERP", within="Bin",
                             subject="Participant", padjust="holm")
print('\nPost-hoc Pairwise Tests:')
print(posthoc[["A", "B", "T", "dof", "p_unc", "p_corr", "p_adjust"]].to_string())
