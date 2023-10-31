subject = 1;
data_path = ['~/Downloads/musicImagery/dataCND/dataSub', num2str(subject), '.mat'];
datapath = join(data_path);
load(data_path)

save('sub1', eeg.data, )