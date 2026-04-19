library(tidyverse)

d <- read_csv("MeanP2adaptersno9_long.csv")

d %>%
  filter(Bin<=6) %>%
  mutate(Participant = as.factor(Participant)) %>%
  ggplot(aes(x=Bin, y=MeanERP, color=Participant)) +
  geom_point() +
  geom_line() +
  theme_bw()

J <- n_distinct(d %>% filter(Bin <= 6) %>% pull(Bin))

d_ws <- d %>%
  filter(Bin <= 6) %>%
  group_by(Participant) %>%
  mutate(MeanERP_norm = MeanERP - mean(MeanERP) + mean(d$MeanERP[d$Bin <= 6])) %>%
  ungroup()

d_ws %>%
  group_by(Bin) %>%
  summarize(
    Mean = mean(MeanERP),
    CI95 = sd(MeanERP_norm) / sqrt(n()) * sqrt(J / (J - 1)) * qt(0.975, df = n() - 1),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = Bin, y = Mean)) +
  geom_point(data = d_ws,
             aes(x = Bin, y = MeanERP, group = Participant),
             color = "grey50", alpha = 0.3, inherit.aes = FALSE) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = Mean - CI95, ymax = Mean + CI95), width = 0.2) +
  labs(y = "Mean ERP") +
  theme_bw()

# Repeated measures ANOVA: MeanERP ~ Bin, within subjects
d_rm <- d %>%
  filter(Bin <= 6) %>%
  mutate(
    Participant = as.factor(Participant),
    Bin = as.factor(Bin)
  )

summary(aov(MeanERP ~ Bin + Error(Participant/Bin), data = d_rm))

# Post-hoc pairwise paired t-tests with Holm correction
pairwise.t.test(d_rm$MeanERP, d_rm$Bin, paired = TRUE, p.adjust.method = "holm")
