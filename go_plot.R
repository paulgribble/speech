
library(tidyverse)

fname = 'will.csv'


df = read_csv(fname)

clist = c("brown", "red", "blue", "orange")

ggplot(data = df) +
  geom_point(mapping = aes(x=trial_num, y=sib_cog, color=token), size=2) + 
  geom_point(mapping = aes(x=trial_num, y=sib_cog_fb, color=token), size=0.5) +
  geom_smooth(data = df %>% filter(trial_num<=35), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) + 
  geom_smooth(data = df %>% filter(trial_num>35), mapping = aes(x=trial_num, y=sib_cog, color=token), method="lm", se=FALSE) + 
  geom_smooth(data = df %>% filter(trial_num>35), mapping = aes(x=trial_num, y=sib_cog_fb, color=token), linewidth=0.5, method="lm", se=FALSE) + 
  geom_vline(xintercept = 35, color="black", linewidth=0.25) + 
  labs(x="Trial Number", y="Centre of Gravity (Hz)", title=fname) + 
  theme_bw() + 
  scale_color_manual(values=clist)

