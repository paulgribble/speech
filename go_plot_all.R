
source("go_plot_exp.R")

dirname = "/Users/plg/Downloads/e/"
participantList = c(1,2,3,4,5,6,7,8,9,10,12,13,14)

for (p in participantList) {
  fname = sprintf("%sTEST1S%02d_extracted.csv", dirname,p)
  plot_experiment(fname)
}

