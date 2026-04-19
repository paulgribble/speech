library(tidyverse)

d <- read_csv("MeanP2adaptersno9_long.csv")

d %>%
  filter(Bin<=6) %>%
  mutate(Participant = as.factor(Participant)) %>%
  ggplot(aes(x=Bin, y=MeanERP, color=Participant)) +
  geom_point() +
  geom_line() +
  theme_bw()

d %>%
  filter(Bin <= 6) %>%
  group_by(Bin) %>%
  summarize(
    Mean = mean(MeanERP),
    SEM  = sd(MeanERP) / sqrt(n()),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = Bin, y = Mean)) +
  geom_point(data = d %>% filter(Bin <= 6),
             aes(x = Bin, y = MeanERP, group = Participant),
             color = "grey50", alpha = 0.3, inherit.aes = FALSE) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = Mean - SEM, ymax = Mean + SEM), width = 0.2) +
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
