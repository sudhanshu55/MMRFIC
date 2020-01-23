%% Function to create the Tx signal for the given list of SVs
%%
%% (C) MMRFIC Technology Pvt. Ltd., Bangalore INDIA
%%---------------------------------------------------------------
%% Usage:
%% function [txSignal, payload, hFilt, codeOffsetArray, freqOffsetArray, symbol] = gpsTx(svIdArray, numBits, OSR, alpha)
%%
%% Version History: (in reverse chronological order please)
%% ver  0.2   17-Jan-2020   Sudhanshu             Codeoffset and Frequency Offset
%% ver  0.1   14-Jan-2020   Sudhanshu             Time and Frequency Domain
%% ver  0.1   10-Jan-2020   Sudhanshu             Created
tic;
clc;
clear all;
close all;
[txSignal, payload, hFilt, codeOffsetArray, freqOffsetArray,svIdArray] = gpsTx();
%% Adding Noise

snr = 0;
txSignal = awgn(txSignal,snr);

%% Reciever

codeLen = 1023;
OSR = 10;
numBits = 10;
Fs = OSR*1e6;
J = sqrt(-1);
hFiltLen = length(hFilt);
[lengthtx,numSVs] =size(txSignal);
% numSVs =1;                                            % to make it run ones

%% Generating gold code with zero offset
allSVs = 32;
refCode = zeros(codeLen*OSR,allSVs);
for nSV = 1:allSVs
    init_g1 = ones(1,10);
    init_g2 = ones(1,10);
    fbMode = ['SV',num2str(nSV)];
    [code, symbol] = GPS_GoldSequence_generator(init_g1, init_g2, codeLen, fbMode, 0);
    refCode(:,nSV) = reshape(repmat(symbol, OSR, 1),OSR*CODE_LEN,1);
end
disp('Goldcode Generated and upsampled by 10');

%% Calculating goldcode used
%offsetMat = zeros(allSVs,codeLen*10);
endvalue = 10230;
for nSV =1:allSVs
for kk = 1:length(dopplerFreqArray)  % +ve freq offset
            freqOffset1 = dopplerFreqArray(kk);
            disp(['Computing correlation for freq :',num2str(freqOffset1)]);

            data1 = data .* exp(-J*2*pi*freqOffset1/Fs*[0:length(data)-1]');
            %corrFFT = (temp .* conj(codeFFT));
            corr1 = conv(data1,flipud(code));
            %corr2 = conv(data1,(code));
            %plot(abs(corr1));hold on; plot(abs(corr2),'r-.');
            corr1 = corr1(5115:end-5115);
            corr(:,ii,kk) = (sum((reshape(corr1,CODE_LEN*OSR,NUM_RPTS*NUM_BITS_AVG)),2));
end
end
%% Frequency Domain

% FrequencyDomain=zeros(numSVs,lengthtx/(1023*OSR));
% for nSV = 1:numSVs
%     temp1 = txSignal(nSV,:);
%     tx = temp1.*exp(J*(-1)*2*pi*freqOffsetArray(nSV)/Fs*[0:lengthtx-1]);
%     tx = real(tx);
%     downsamtx = downsample(tx,OSR);
%     downsamtx_hfilt = conv(downsamtx,hFilt);
%     downsamtx_hfilt = downsamtx_hfilt((hFiltLen-1)/2+1:end-(hFiltLen-1)/2);
%     starting =1;
%     i=1;
%     goldCodeFFT = conj(fft(symbol(nSV,:)));
%     for val = 1023:1023:length(downsamtx_hfilt)
%         payloadFFT = fft(downsamtx_hfilt(starting:val));
%         crossCorr_FFT = ifft(payloadFFT .*goldCodeFFT);
%         starting = starting +1023;
%         FrequencyDomain(nSV,i) =crossCorr_FFT(1);
%         i=i+1;
%         
%     end
% end
% avgValuefreq = zeros(1,numBits);
% freq = 20;                                %50Hz 
% for nSV = 1:numSVs
%     val = 0;
%     lastval = 0;
%     for i =1:freq:length(FrequencyDomain)
%         DataFreq = FrequencyDomain(nSV,:);
%         lastval = lastval+freq;
%         avg = sum(DataFreq(i:1:lastval))/freq;
%         val = val +1;
%         avgValuefreq(val)=avg;
%     end
%     outputfreq = (1*(avgValuefreq >0));
%     error = sum(bitxor(outputfreq,payload));
%     disp (['Error for SNR ',num2str(snr),' in SV ',num2str(nSV),'  is ', num2str(error), ' in Frequency Domain']);
% end 
toc;