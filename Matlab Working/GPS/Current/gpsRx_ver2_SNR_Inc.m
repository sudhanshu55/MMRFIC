%% Function to create the Tx signal for the given list of SVs
%%
%% (C) MMRFIC Technology Pvt. Ltd., Bangalore INDIA
%%---------------------------------------------------------------
%% Usage:
%% function [txSignal, payload, hFilt, codeOffsetArray, freqOffsetArray, symbol] = gpsTx(svIdArray, numBits, OSR, alpha)
%%
%% Version History: (in reverse chronological order please)
%% ver  0.2   17-Jan-2020   Sudhanshu             Gold code with Codeoffset and Frequency Offset
%% ver  0.1   14-Jan-2020   Sudhanshu             Time and Frequency Domain
%% ver  0.1   10-Jan-2020   Sudhanshu             Created
%% changes - Zero offset,
tic;
clc;
clear all;
close all;
[txSignal, payload, hFilt, codeOffsetArray, freqOffsetArray,svIdArray] = gpsTx();
%% Adding Noise

snr = 0;
%txSignal = awgn(txSignal,snr);
rxSignal = 10^(snr/20) * sum(txSignal,2) + randn(length(txSignal),1);
%% Reciever

codeLen = 1023;
OSR = 10;
numRep = 20;
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
    refCode(:,nSV) = reshape(repmat(symbol, OSR, 1),OSR*codeLen,1);
end
% disp('Goldcode Generated and upsampled by 10');

%% Calculating goldcode used
data = rxSignal(1:codeLen*OSR*numRep);
GoldCodeUsed = zeros(codeLen*10*numRep,allSVs);
endvalue = codeLen*10*numRep;
goldval = zeros(1,6);
for CurrSV =1:numSVs
for nSV =1:allSVs
    code = refCode(:,nSV);
    corr1 = conv(data,flipud(code));
    corr = corr1(5115:end-5115);
    GoldCodeUsed(:,nSV) = corr;
    [tempMax,maxIndex] = max(abs(GoldCodeUsed));
end
[maxPeak(CurrSV), goldval(CurrSV)] = max(tempMax);
end
disp(['Actual Gold code used    ', num2str(svIdArray)]);
disp(['Predicted Gold code used ',num2str(goldval)]);
toc;