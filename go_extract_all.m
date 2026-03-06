
participantList = [1,2,3,4,5,6,7,8,9,10,12,13,14];
n = length(participantList);
fprintf("extracting %n scored participants\n")
for i=1:n
    fname = sprintf("TEST1S%02d_scored.csv", participantList(i));
    fprintf("extracting %s ...\n", fname)
    go_extract(fname, false);
end

