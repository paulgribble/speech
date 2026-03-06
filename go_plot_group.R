
library(tidyverse)

# Load and concatenate all participant files
fnames = list.files(pattern = "TEST1S\\d+_extracted\\.csv")

df_all = map_dfr(fnames, read_csv) %>% filter(trial_num <= 281)

# Compute mean and SEM per trial_num and token
sem = function(x) sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x)))

df_summary = df_all %>%
  group_by(trial_num, token) %>%
  summarise(
    mean_cog    = mean(sib_cog,    na.rm = TRUE),
    se_cog      = sem(sib_cog),
    mean_cog_fb = mean(sib_cog_fb, na.rm = TRUE),
    se_cog_fb   = sem(sib_cog_fb),
    .groups = "drop"
  )

clist = c("see" = "brown", "she" = "red", "shoe" = "blue", "sue" = "orange")

myplot = ggplot(data = df_summary) +
  # SEM ribbons
  geom_ribbon(mapping = aes(x = trial_num,
                             ymin = mean_cog - se_cog,
                             ymax = mean_cog + se_cog,
                             fill = token), alpha = 0.2) +
  geom_ribbon(mapping = aes(x = trial_num,
                             ymin = mean_cog_fb - se_cog_fb,
                             ymax = mean_cog_fb + se_cog_fb,
                             fill = token), alpha = 0.1) +
  # Mean lines
  geom_line(mapping = aes(x = trial_num, y = mean_cog,    color = token), linewidth = 0.5) +
  geom_line(mapping = aes(x = trial_num, y = mean_cog_fb, color = token), linewidth = 0.3, linetype = "dashed", alpha = 0.5) +
  # LM trend lines per phase - sib_cog
  geom_smooth(data = df_summary %>% filter(trial_num <= 22),
              mapping = aes(x = trial_num, y = mean_cog, color = token), method = "lm", se = FALSE) +
  geom_smooth(data = df_summary %>% filter(trial_num > 23,  trial_num <= 73),
              mapping = aes(x = trial_num, y = mean_cog, color = token), method = "lm", se = FALSE) +
  geom_smooth(data = df_summary %>% filter(trial_num > 75,  trial_num <= 281),
              mapping = aes(x = trial_num, y = mean_cog, color = token), method = "lm", se = FALSE) +
  geom_smooth(data = df_summary %>% filter(trial_num > 283),
              mapping = aes(x = trial_num, y = mean_cog, color = token), method = "lm", se = FALSE) +
  # LM trend lines per phase - sib_cog_fb (dashed)
  geom_smooth(data = df_summary %>% filter(trial_num > 23,  trial_num <= 73),
              mapping = aes(x = trial_num, y = mean_cog_fb, color = token), linewidth = 0.3, linetype = "dashed", method = "lm", se = FALSE, alpha = 0.5) +
  geom_smooth(data = df_summary %>% filter(trial_num > 75,  trial_num <= 281),
              mapping = aes(x = trial_num, y = mean_cog_fb, color = token), linewidth = 0.3, linetype = "dashed", method = "lm", se = FALSE, alpha = 0.5) +
  geom_smooth(data = df_summary %>% filter(trial_num > 283),
              mapping = aes(x = trial_num, y = mean_cog_fb, color = token), linewidth = 0.3, linetype = "dashed", method = "lm", se = FALSE, alpha = 0.5) +
  # Phase boundaries
  geom_vline(xintercept = 23,  color = "black", linewidth = 0.25) +
  geom_vline(xintercept = 75,  color = "black", linewidth = 0.25) +
  geom_vline(xintercept = 283, color = "black", linewidth = 0.25) +
  labs(x = "Trial Number", y = "COG (Hz)", title = "Group Average (N=13, ±1 SEM)") +
  theme_bw() +
  scale_color_manual(values = clist) +
  scale_fill_manual(values = clist)

myplot

ggsave(filename = "TEST1_group_average.pdf", plot = myplot, width = 8, height = 6, units = "in")

# Per-participant LM lines plot
myplot_pp = ggplot(data = df_all) +
  # LM trend lines per phase per participant - sib_cog
  geom_smooth(data = df_all %>% filter(trial_num <= 22),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.4) +
  geom_smooth(data = df_all %>% filter(trial_num > 23,  trial_num <= 73),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.4) +
  geom_smooth(data = df_all %>% filter(trial_num > 75,  trial_num <= 281),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.4) +
  geom_smooth(data = df_all %>% filter(trial_num > 283),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.4) +
  # LM trend lines per phase per participant - sib_cog_fb (dashed)
  geom_smooth(data = df_all %>% filter(trial_num > 23,  trial_num <= 73),
              mapping = aes(x = trial_num, y = sib_cog_fb, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.2, linetype = "dashed", alpha = 0.2) +
  geom_smooth(data = df_all %>% filter(trial_num > 75,  trial_num <= 281),
              mapping = aes(x = trial_num, y = sib_cog_fb, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.2, linetype = "dashed", alpha = 0.2) +
  geom_smooth(data = df_all %>% filter(trial_num > 283),
              mapping = aes(x = trial_num, y = sib_cog_fb, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.2, linetype = "dashed", alpha = 0.2) +
  # Phase boundaries
  geom_vline(xintercept = 23,  color = "black", linewidth = 0.25) +
  geom_vline(xintercept = 75,  color = "black", linewidth = 0.25) +
  geom_vline(xintercept = 283, color = "black", linewidth = 0.25) +
  labs(x = "Trial Number", y = "COG (Hz)", title = "Per-Participant LM Fits (N=13)") +
  theme_bw() +
  scale_color_manual(values = clist)

myplot_pp

ggsave(filename = "TEST1_per_participant.pdf", plot = myplot_pp, width = 8, height = 6, units = "in")

# Normalised per-participant plot
# she/shoe: normalise to trials 24-73; see/sue: normalise to trials <=22
participant_means = bind_rows(
  df_all %>%
    filter(trial_num >= 24, trial_num <= 73, token %in% c("she", "shoe")) %>%
    group_by(participant, token) %>%
    summarise(p_mean_cog    = mean(sib_cog,    na.rm = TRUE),
              p_mean_cog_fb = mean(sib_cog_fb, na.rm = TRUE),
              .groups = "drop"),
  df_all %>%
    filter(trial_num <= 22, token %in% c("see", "sue")) %>%
    group_by(participant, token) %>%
    summarise(p_mean_cog    = mean(sib_cog,    na.rm = TRUE),
              p_mean_cog_fb = mean(sib_cog_fb, na.rm = TRUE),
              .groups = "drop")
)

grand_means = bind_rows(
  df_all %>%
    filter(trial_num >= 24, trial_num <= 73, token %in% c("she", "shoe")) %>%
    group_by(token) %>%
    summarise(g_mean_cog    = mean(sib_cog,    na.rm = TRUE),
              g_mean_cog_fb = mean(sib_cog_fb, na.rm = TRUE),
              .groups = "drop"),
  df_all %>%
    filter(trial_num <= 22, token %in% c("see", "sue")) %>%
    group_by(token) %>%
    summarise(g_mean_cog    = mean(sib_cog,    na.rm = TRUE),
              g_mean_cog_fb = mean(sib_cog_fb, na.rm = TRUE),
              .groups = "drop")
)

df_norm = df_all %>%
  left_join(participant_means, by = c("participant", "token")) %>%
  left_join(grand_means, by = "token") %>%
  mutate(sib_cog    = sib_cog    - p_mean_cog    + g_mean_cog,
         sib_cog_fb = sib_cog_fb - p_mean_cog_fb + g_mean_cog_fb) %>%
  select(-p_mean_cog, -p_mean_cog_fb, -g_mean_cog, -g_mean_cog_fb)

myplot_norm = ggplot(data = df_norm) +
  # LM trend lines per phase per participant - sib_cog
  geom_smooth(data = df_norm %>% filter(trial_num <= 22),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.1) +
  geom_smooth(data = df_norm %>% filter(trial_num > 23,  trial_num <= 73),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.1) +
  geom_smooth(data = df_norm %>% filter(trial_num > 75,  trial_num <= 281),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.1) +
  geom_smooth(data = df_norm %>% filter(trial_num > 283),
              mapping = aes(x = trial_num, y = sib_cog, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.4, alpha = 0.1) +
  # LM trend lines per phase per participant - sib_cog_fb (dashed)
  geom_smooth(data = df_norm %>% filter(trial_num > 23,  trial_num <= 73),
              mapping = aes(x = trial_num, y = sib_cog_fb, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.2, linetype = "dashed", alpha = 0.05) +
  geom_smooth(data = df_norm %>% filter(trial_num > 75,  trial_num <= 281),
              mapping = aes(x = trial_num, y = sib_cog_fb, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.2, linetype = "dashed", alpha = 0.05) +
  geom_smooth(data = df_norm %>% filter(trial_num > 283),
              mapping = aes(x = trial_num, y = sib_cog_fb, color = token, group = interaction(token, participant)), method = "lm", se = FALSE, linewidth = 0.2, linetype = "dashed", alpha = 0.05) +
  # Phase boundaries
  geom_vline(xintercept = 23,  color = "black", linewidth = 0.25) +
  geom_vline(xintercept = 75,  color = "black", linewidth = 0.25) +
  geom_vline(xintercept = 283, color = "black", linewidth = 0.25) +
  labs(x = "Trial Number", y = "COG (Hz)", title = "Per-Participant LM Fits, Normalised (she/shoe: trials 24-73; see/sue: trials \u226422) (N=13)") +
  theme_bw() +
  scale_color_manual(values = clist)

myplot_norm

ggsave(filename = "TEST1_per_participant_norm.pdf", plot = myplot_norm, width = 8, height = 6, units = "in")
