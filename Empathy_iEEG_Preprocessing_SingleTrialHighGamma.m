clear classes
cd('/Users/kexin/Downloads/data/PT063')
addpath(genpath('/Users/kexin/Downloads/THIENC_iEEG_Task_Preprocessing_Base'))
addpath('/Users/kexin/Downloads/spm/spm12')
%addpath('C:\Users\THIENC\Desktop\eeglab14_1_2b')
%% iEEG
clear
h = iEEG;

h.TaskName = 'Empathy';

% Convert iEEG
try
    load('EDFChannels.mat')
    h.Converter_EDF([],index_to_keep)
catch
    h.Converter_EDF([],[])
end


% Convert DC
disp('Converting DC channels')
h.Converter_EDF([],[],[],1);

% load mat file
h.LoadMatFiles;

% Downsampling
h.DownSampling

% Rename channels
h.RenameChan

% Remove line noise
h.RemoveLineNoise

% Set bad channels before
h.SetBadChannels

% Rereference to common average
h.Montage_Avg

% % High pass filter to minimize low frequency contaminatin (1Hz high pass filter)
% h.HighPassFilter

% % clone and import EEGlab processed iEEG data
% updatediEEG = clone(h.iEEG_MEEG{1},'ICAed');
% updatediEEG(:,:,1) = EEG.data;
% h.iEEG_MEEG{1} = updatediEEG;

% Get triggers and compare triggers from DC and mat
h.GetDCTimeStamps
h.GetMatTimeStamps
h.TimeStampsComp


h.EpochWin = [-1000 4000];
% Epoch data
h.EpochiEEG

h.SetConditions

% Set conditions in MEEG data
D = h.iEEG_MEEG{1};
D = struct(D);
for i = 1:length(D.trials)
    D.trials(i).tag = h.Conditions1{1}(i);
end
D = meeg(D);
save(D)
%% Convert to edf
D = spm_eeg_load;
SPMEEG2EDFConvert(D)

%% Combine all the session
clear S
S.D = spm_select();
spm_eeg_merge(S)


%%
% % Plot raw traces
% h = iEEG;
% h.LoadiEEGMEEG

% PlotERPs_Raw(h,Baseline)
% PlotERPs_Mean(h,Baseline)

spm('defaults','eeg')
D = spm_eeg_load;
Baseline = [-300 0];
SampleInterval = [find(round(D.time * D.fsample) == Baseline(1)):find((D.time * D.fsample) == 3000)];

mkdir('figs')
cd('figs')
for i = 1:D.nchannels
    ChannelInd = i;
    Data = squeeze(D(ChannelInd,:,:));
    figure
    toPlotPain = Data(SampleInterval,find(D.trialtag));
    toPlotPain = toPlotPain - mean(toPlotPain(1:300,:));
    plot(D.time(SampleInterval),toPlotPain,'Color',[250 212 192 150]/255);
    grid on
    hold on
    
    toPlotNeutral = Data(SampleInterval,find(~D.trialtag));
    toPlotNeutral = toPlotNeutral - mean(toPlotNeutral(1:300,:));
    plot(D.time(SampleInterval),toPlotNeutral,'Color',[192 253 251 150]/255);
    grid on
    hold on
    plot(D.time(SampleInterval),mean(toPlotPain,2),'LineWidth',2,'Color','r')
    plot(D.time(SampleInterval),mean(toPlotNeutral,2),'LineWidth',2,'Color','b')
    axis tight
    
    title([D.chanlabels{i} '_' 'RawTrace'],'Interpreter','none');
    set(gca,'FontSize',14)
    %set(findobj(gca,'type','line'),'linew',4)
    set(gcf,'Position',[0 100 1920 600])
    print([D.chanlabels{i} '_' 'RawTrace'],'-dpng')
    close
end

%% For time frequency analysis
spm('defaults','eeg')
D = spm_eeg_load();

for i = 1:D.nchannels
    tempData = squeeze(D(i,:,:));
    t = 0:1/D.fsample:7;
    freq = 1:300;
    P = morlet_transform(tempData', t, freq);
end

% Baseline normalization
for i = 1:72
    BaseLine = squeeze(P(i,:,1601:2000));
    % Percent change baseline normalization
    PBaseLine(i,:,:) = (squeeze(P(i,:,:)) - mean(BaseLine,2)) ./ mean(BaseLine,2);   
end

% for i = 1:72
%     PLog(i,:,:) = log10(squeeze(P(i,:,:)));
% end

% High gamma response for a single trials
for i = 1:72
PPlot = squeeze(PBaseLine(i,:,:));
SingleHighGammaPlot = mean(PPlot(70:200,1000:6000));
figure
plot(SingleHighGammaPlot)
axis tight
grid on
end

% Energy caculation for a single trial
i=1:72
HighGammaPlot = mean(PBaseLine(i,70:200,1000:6000),2);
aa = squeeze(HighGammaPlot);
%time window 1
Energy1 = mean(aa(i,1300:1700),2)
%time window 2
Energy2 = mean(aa(i,1700:4500),2)















