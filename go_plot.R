
library(tidyverse)

fname = 'will.csv'




df = read_csv(fname)

clist = c("brown", "red", "blue", "orange")

myplot = ggplot(data = df) +
  geom_point(mapping = aes(x=trial_num, y=sib_cog, color=token), size=1) + 
  geom_point(mapping = aes(x=trial_num, y=sib_cog_fb, color=token), size=0.3, alpha=0.2) +
  geom_smooth(data = df %>% filter(trial_num<=35), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) + 
  geom_smooth(data = df %>% filter(trial_num>35), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) + 
  geom_smooth(data = df %>% filter(trial_num>35), mapping = aes(x=trial_num, y=sib_cog_fb, color=token), linewidth=0.3, linetype="dashed", method="lm", se=FALSE, alpha=0.2) + 
  geom_vline(xintercept = 35, color="black", linewidth=0.25) + 
  labs(x="Trial Number", y="Centre of Gravity (Hz)", title=fname) + 
  theme_bw() + 
  scale_color_manual(values=clist)

myplot

fname_plot = paste(str_split(fname,'.csv')[[1]][1],".pdf", sep = "")
ggsave(filename=fname_plot, plot=myplot, width=8, height=6, units="in")
