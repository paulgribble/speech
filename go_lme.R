library(lme4)
library(lmerTest)

# Load data
d <- read.csv("~/Dropbox/data/julia_speech/speech/Exp_behav/e/centroids.csv")

# Keep only "she" and "shoe" tokens, trials 1-282, learning phase (74-282)
d <- d[d$token %in% c("she", "shoe") & d$trial_num >= 74 & d$trial_num <= 282, ]

# Create a learning-phase trial counter scaled to [0,1]
d$learning_trial <- (d$trial_num - 74) / (282 - 74)

# Factor
d$participant <- factor(d$participant)

# Fit LME: sib_cog ~ learning_trial with random intercept + slope per participant
m <- lmer(sib_cog ~ learning_trial +
            (1 + learning_trial | participant),
          data = d, REML = TRUE)

cat("\n=== Model Summary ===\n\n")
print(summary(m))

cat("\n=== ANOVA (Type III) ===\n\n")
print(anova(m))

# --- Per-participant intercepts and slopes ---

fe <- fixef(m)
re <- ranef(m)$participant

pars <- data.frame(
  participant = rownames(re),
  intercept = fe["(Intercept)"] + re[["(Intercept)"]],
  slope = fe["learning_trial"] + re[["learning_trial"]]
)
pars <- pars[order(pars$slope), ]

cat("\n=== Participant Intercepts and Slopes ===\n\n")
print(pars, row.names = FALSE)

# --- Plots ---

library(ggplot2)

# 1. Histogram of participant intercepts
p1 <- ggplot(pars, aes(x = intercept)) +
  geom_histogram(bins = 15, color = "white", fill = "steelblue") +
  labs(x = "Intercept (sib_cog at start of learning)", y = "Count",
       title = "Distribution of participant intercepts") +
  theme_minimal()

# 2. Histogram of participant slopes
p2 <- ggplot(pars, aes(x = slope)) +
  geom_histogram(bins = 15, color = "white", fill = "steelblue") +
  geom_vline(xintercept = 0, linetype = "dotted", color = "grey50") +
  labs(x = "Slope (change in sib_cog over learning phase)", y = "Count",
       title = "Distribution of participant slopes") +
  theme_minimal()

# 3. Intercept vs slope scatter
p3 <- ggplot(pars, aes(x = intercept, y = slope)) +
  geom_point(size = 2, color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
  labs(x = "Intercept", y = "Slope",
       title = "Participant intercepts vs slopes") +
  theme_minimal()

# 4. Per-participant model fits overlaid on raw data
d$fitted <- NA
d$fitted[complete.cases(d[, c("sib_cog", "learning_trial", "participant")])] <- fitted(m)
p4 <- ggplot(d, aes(x = learning_trial, y = sib_cog)) +
  geom_point(alpha = 0.2, size = 0.5) +
  geom_line(aes(y = fitted, color = participant), linewidth = 0.6) +
  labs(x = "Learning trial (scaled 0-1)", y = "sib_cog",
       title = "Model fits per participant") +
  theme_minimal() +
  theme(legend.position = "none")

# Save to PDF
pdf("go_lme_plots.pdf", width = 10, height = 8)
print(p1)
print(p2)
print(p3)
print(p4)
dev.off()
cat("\nPlots saved to go_lme_plots.pdf\n")

# --- First 10 vs Last 10 trials x Token (2x2 repeated measures) ---

# Reload full learning-phase data with token preserved
d2 <- read.csv("~/Dropbox/data/julia_speech/speech/Exp_behav/e/centroids.csv")
d2 <- d2[d2$token %in% c("she", "shoe") & d2$trial_num >= 74 & d2$trial_num <= 282, ]

# First 10 and last 10 learning-phase trials
first10 <- sort(unique(d2$trial_num))[1:10]
last10  <- tail(sort(unique(d2$trial_num)), 10)
d2 <- d2[d2$trial_num %in% c(first10, last10), ]

d2$phase <- ifelse(d2$trial_num %in% first10, "first10", "last10")
d2$phase <- factor(d2$phase, levels = c("first10", "last10"))
d2$token <- factor(d2$token)
d2$participant <- factor(d2$participant)

# Aggregate to participant means per cell
d2_agg <- aggregate(sib_cog ~ participant + phase + token, data = d2, FUN = mean)

# 2x2 repeated-measures LME: phase * token with random intercept per participant
m2 <- lmer(sib_cog ~ phase * token + (1 + phase | participant), data = d2_agg, REML = TRUE)

cat("\n=== First 10 vs Last 10 x Token: Model Summary ===\n\n")
print(summary(m2))

cat("\n=== First 10 vs Last 10 x Token: ANOVA (Type III) ===\n\n")
print(anova(m2))
