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


def load_long(path, group):
    df = pd.read_csv(path)
    df = (
        df.rename(columns={"ERPset": "Participant"})
        .melt(
            id_vars="Participant",
            value_vars=[f"bin{i}_Midline" for i in range(1, 9)],
            var_name="Bin",
            value_name="MeanERP",
        )
        .assign(Bin=lambda x: x["Bin"].str.extract(r"bin(\d+)").astype(int))
    )
    df["Group"] = group
    return df

d = pd.concat([
    load_long("MeanP2adaptersno9.csv", "adapters"),
    load_long("MeanP2nonadapters.csv", "nonadapters"),
    load_long("MeanP2controls.csv", "controls"),
], ignore_index=True)
d = d[d["Bin"] <= 6].copy()
d["Participant"] = d["Participant"].astype(str)
d["Bin"] = d["Bin"].astype(int)

# Plot 1: individual participant trajectories, one subpanel per Group
groups = ["adapters", "nonadapters", "controls"]
fig, axes = plt.subplots(3, 1, figsize=(4, 10), sharex=True, sharey=True)
for ax, group in zip(axes, groups):
    sns.lineplot(data=d[d["Group"] == group], x="Bin", y="MeanERP",
                 hue="Participant", marker="o", ax=ax, legend=False)
    ax.set_xlabel("Bin")
    ax.set_ylabel("Mean ERP")
    ax.set_xlim([0.5, 6.5])
    ax.set_ylim([0.5, 8])
    ax.set_title(group)
    sns.despine(ax=ax)
    ax.spines['bottom'].set_bounds(1, 6)
    ax.spines['left'].set_bounds(1, 8)
plt.tight_layout()
fname = "plot1_individual_trajectories.png"
print(f"saving plot to {fname}")
plt.savefig(fname, dpi=150)
plt.close()

# Plot 2: group mean +/- 95% within-subject CI (Cousineau-Morey), all groups on one plot
fig, ax = plt.subplots(figsize=(4, 4))
colors = {"adapters": "C0", "nonadapters": "C1", "controls": "C2"}
for group in groups:
    bin_means = cousineau_morey_ci(d[d["Group"] == group].copy(),
                                   'Participant', 'Bin', 'MeanERP')
    ax.errorbar(bin_means["Bin"], bin_means["mean"],
                yerr=bin_means["ci_half_width"], fmt="o-",
                color=colors[group], capsize=4, linewidth=1.5, label=group)
ax.set_xlabel("Bin")
ax.set_ylabel("Mean ERP")
ax.set_ylim([2.5, 7])
ax.set_yticks([3, 4, 5, 6])
ax.set_xlim([0.5, 6.5])
ax.legend(frameon=False)
sns.despine()
ax.spines['bottom'].set_bounds(1, 6)
ax.spines['left'].set_bounds(3, 6)
plt.tight_layout()
fname = "plot2_group_mean_ci.png"
print(f"saving plot to {fname}")
plt.savefig(fname, dpi=150)
plt.close()


# Mixed ANOVA: Group (between) x Bin (within)
mixed_aov = pg.mixed_anova(data=d, dv="MeanERP", within="Bin",
                           between="Group", subject="Participant")

# Repeated-measures ANOVA on adapters only: MeanERP ~ Bin (within subjects)
d_adapters = d[d["Group"] == "adapters"]
aov = pg.rm_anova(data=d_adapters, dv="MeanERP", within="Bin",
                  subject="Participant", detailed=True)

# Post-hoc pairwise paired t-tests (adapters) with Holm correction
posthoc = pg.pairwise_tests(data=d_adapters, dv="MeanERP", within="Bin",
                            subject="Participant", padjust="holm")

with open("stats.txt", "w") as f:
    f.write("Mixed ANOVA: Group (between) x Bin (within)\n")
    f.write("-"*45 + "\n")
    f.write(mixed_aov.to_string() + "\n")
    f.write("\nRepeated Measures ANOVA (adapters only)\n")
    f.write("-"*45 + "\n")
    f.write(aov.to_string() + "\n")
    f.write("\nPost-hoc Pairwise Tests (adapters):\n")
    f.write("-"*45 + "\n")
    f.write(posthoc[["A", "B", "T", "dof", "p_unc", "p_corr", "p_adjust"]].to_string() + "\n")
print("stats written to stats.txt")
