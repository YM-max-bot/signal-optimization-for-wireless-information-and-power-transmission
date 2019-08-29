%% Subband
a = channelAmplitude(1);
clearvars channelAmplitude;
channelAmplitude{1} = a;
channelAmplitude{2} = repmat(a,[2,1]);
channelAmplitude{3} = repmat(a,[4,1]);
channelAmplitude{4} = repmat(a,[8,1]);
channelAmplitude{5} = repmat(a,[16,1]);

for iCase = 1: Variable.nSubbandCases
    Channel.subband = Variable.subband(iCase);
    Channel.sampleFrequency = Variable.sampleFrequency{iCase};
    Channel.gapFrequency = Variable.gapFrequency(iCase);
    % obtain the channel amplitude corresponding to the carrier frequency
    [Channel] = channel_response(Transceiver, Channel);
    channelAmplitude{iCase} = Channel.subbandAmplitude;
end

Variable.nSubbandCases = 5;
Variable.nSamples = 41;
Variable.subband = [1 2 4 8 16];

for iCase = 1: Variable.nSubbandCases
    lambda = channelAmplitude{iCase}(:) .^ 2;
    subbandPower = water_filling(lambda, 2 * txPower, noisePowerRef);
    % average rate per subband
    maxRate(iCase) = sum(log2(1 + subbandPower / noisePowerRef.* lambda)) / nSubbands(iCase);
end

for iCase = 1: Variable.nSubbandCases
    rateDecoupling(iCase, Variable.nSamples + 1) = maxRate(iCase); currentDecoupling(iCase, Variable.nSamples + 1) = 0;
    rateNoPowerWaveform(iCase, Variable.nSamples + 1) = maxRate(iCase); currentNoPowerWaveform(iCase, Variable.nSamples + 1) = 0;
    [rateDecoupling(iCase, :), indexDecoupling] = sort(rateDecoupling(iCase, :)); currentDecoupling(iCase, :) = currentDecoupling(iCase, indexDecoupling);
    [rateNoPowerWaveform(iCase, :), indexNoPowerWaveform] = sort(rateNoPowerWaveform(iCase, :)); currentNoPowerWaveform(iCase, :) = currentNoPowerWaveform(iCase, indexNoPowerWaveform);
end
%% SNR
for iCase = 1: length(noisePower)
    lambda = channelAmplitude(:) .^ 2;
    subbandPower = water_filling(lambda, 2 * txPower, noisePower(iCase));
    % average rate per subband
    maxRate(iCase) = sum(log2(1 + subbandPower / noisePower(iCase).* lambda)) / nSubbandsRef;
end

for iCase = 1: Variable.nSnrCases
    rateDecoupling(iCase, nRateSamples + 1) = maxRate(iCase); currentDecoupling(iCase, nRateSamples + 1) = 0;
    rateLowerBound(iCase, nRateSamples + 1) = maxRate(iCase); currentLowerBound(iCase, nRateSamples + 1) = 0;
    rateNoPowerWaveform(iCase, nRateSamples + 1) = maxRate(iCase); currentNoPowerWaveform(iCase, nRateSamples + 1) = 0;
    [rateDecoupling(iCase, :), indexDecoupling] = sort(rateDecoupling(iCase, :)); currentDecoupling(iCase, :) = currentDecoupling(iCase, indexDecoupling);
    [rateLowerBound(iCase, :), indexLowerBound] = sort(rateLowerBound(iCase, :)); currentLowerBound(iCase, :) = currentLowerBound(iCase, indexLowerBound);
    [rateNoPowerWaveform(iCase, :), indexNoPowerWaveform] = sort(rateNoPowerWaveform(iCase, :)); currentNoPowerWaveform(iCase, :) = currentNoPowerWaveform(iCase, indexNoPowerWaveform);
end

rateLowerBound(:, 3:end) = rateNoPowerWaveform(:, 3:end);
for iCase = 1: Variable.nSnrCases
    currentLowerBound_ = currentLowerBound(iCase, :); currentNoPowerWaveform_ = currentNoPowerWaveform(iCase, :);
    currentLowerBound_(currentLowerBound_<currentNoPowerWaveform_) = currentNoPowerWaveform_(currentLowerBound_<currentNoPowerWaveform_);
    currentLowerBound(iCase, :) = currentLowerBound_;
end

clearvars currentLowerBound_ currentNoPowerWaveform_
%% MIMO
for iCase = 1: Variable.nRxCases
    [maxRate(iCase)] = wit(Transceiver{iCase}, Channel{iCase});
    rateMimo(iCase, Variable.nSamples + 1) = maxRate(iCase); currentMimo(iCase, Variable.nSamples + 1) = 0;
    [rateMimo(iCase, :), indexDecoupling] = sort(rateMimo(iCase, :)); currentMimo(iCase, :) = currentMimo(iCase, indexDecoupling);
end
%% PAPR
currentPapr(3, :) = max(currentPapr);
currentPapr(2, :) = max(currentPapr(1:2, :));
%% Optimal stragegy for medium N
legendStr = cell(3, 1);
figure('Name', 'Superposed waveform');
% WIPT
for iCase = 4
    plot(rateDecoupling(iCase, :), currentDecoupling(iCase, :) * 1e6, 'r');
    legendStr{1} = sprintf('WIPT (PS + TS): N = %d', Variable.subband(iCase));
    hold on;
end
% WIPT
for iCase = 4
    plot(rateDecoupling(iCase, 1:14), currentDecoupling(iCase, 1:14) * 1e6, 'k');
    legendStr{2} = sprintf('WIPT (PS): N = %d', Variable.subband(iCase));
    hold on;
end
% WIT
for iCase = 4
    scatter(maxRate(iCase), 0, 'k');
    legendStr{3} = sprintf('WIT: N = %d', Variable.subband(iCase));
    hold on;
end
% time-sharing
for iCase = 4
    plot([rateDecoupling(iCase, 1), maxRate(iCase)], [currentDecoupling(iCase, 1) * 1e6, 0], 'k--');
    legendStr{4} = sprintf('WIPT (TS): N = %d', Variable.subband(iCase));
    hold on;
end
% plot([rateDecoupling(iCase, 1), maxRate(iCase)], [currentDecoupling(iCase, 1) * 1e6, 0], 'r')
plot([rateDecoupling(iCase, 1), rateDecoupling(iCase, 14)], [currentDecoupling(iCase, 1), currentDecoupling(iCase, 14)] * 1e6, 'r');
hold off;
grid on; grid minor;
legend(legendStr);
xlabel('Rate [bps/Hz]');
ylabel('I_{DC} [\muA]');
ylim([0, 6]);
