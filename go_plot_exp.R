
library(tidyverse)

plot_experiment = function(fname = NULL) {
  if (is.null(fname)) {
    fname = file.choose()
  }

  df = read_csv(fname) %>% filter(trial_num <= 281)

  clist = c("see" = "brown", "she" = "red", "shoe" = "blue", "sue" = "orange")

  myplot = ggplot(data = df) +
    geom_point(mapping = aes(x=trial_num, y=sib_cog, color=token), size=1) +
    geom_point(mapping = aes(x=trial_num, y=sib_cog_fb, color=token), size=0.3, alpha=0.2) +
    geom_smooth(data = df %>% filter(trial_num<=22), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) +
    geom_smooth(data = df %>% filter(trial_num>23, trial_num<=73), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) +
    geom_smooth(data = df %>% filter(trial_num>23, trial_num<=73), mapping = aes(x=trial_num, y=sib_cog_fb, color=token), linewidth=0.3, linetype="dashed", method="lm", se=FALSE, alpha=0.2) +
    geom_smooth(data = df %>% filter(trial_num>75, trial_num<=281), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) +
    geom_smooth(data = df %>% filter(trial_num>75, trial_num<=281), mapping = aes(x=trial_num, y=sib_cog_fb, color=token), linewidth=0.3, linetype="dashed", method="lm", se=FALSE, alpha=0.2) +
    geom_smooth(data = df %>% filter(trial_num>283), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) +
    geom_smooth(data = df %>% filter(trial_num>283), mapping = aes(x=trial_num, y=sib_cog_fb, color=token), linewidth=0.3, linetype="dashed", method="lm", se=FALSE, alpha=0.2) +
    geom_vline(xintercept = 23, color="black", linewidth=0.25) +
    geom_vline(xintercept = 75, color="black", linewidth=0.25) +
    geom_vline(xintercept = 283, color="black", linewidth=0.25) +
    labs(x="Trial Number", y="COG (Hz)", title=fname) +
    theme_bw() +
    scale_color_manual(values=clist)

  print(myplot)

  fname_plot = paste(str_split(fname, '.csv')[[1]][1], ".pdf", sep = "")
  ggsave(filename=fname_plot, plot=myplot, width=8, height=6, units="in")
}
