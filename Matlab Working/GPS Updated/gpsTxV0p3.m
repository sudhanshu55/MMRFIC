%% Function to create the Tx signal for the given list of SVs
%% 
%% (C) MMRFIC Technology Pvt. Ltd., Bangalore INDIA
%%---------------------------------------------------------------
%% Usage:
%% function [txSignal, payload, hFilt, codeOffsetArray, freqOffsetArray] = gpsTx(svIdArray, numBits, OSR, alpha)
%%
%% Version History: (in reverse chronological order please)
%%
%% ver  0.3   25-Feb-2020   Ganesan, T             Random freq offset for all SVs 
%%                                                 but all within +/- 500 Hz for eacy search 
%% ver  0.2   17-Jan-2020   Ganesan, T             Fixed the order of kron product, returned the svIdArray
%%                                                 Fixed the randi() call 
%% ver  0.1   06-Jan-2020   Ganesan, T             Created 

function [txSignal, payload, hFilt, codeOffsetArray, freqOffsetArray, svIdArray] = gpsTxV0p3(svIdArray, numBits, OSR, alpha, maxDoppFreq)

if (nargin < 1)
    svIdArray = randi(32,1,5);    % Random 5 SVs
end

if (nargin < 2)
    numBits = 10;  % 10*20 msec duration
end

if (nargin < 3)
    OSR = 10;      % 10x oversampling => 10.23 MHz sampling rate
end

if (nargin < 4)
    alpha = 0.25;   % Default excess bandwidth for root Raised cosine pulse 
end
if (nargin < 5)
    maxDoppFreq = 5000;   % Default excess bandwidth for root Raised cosine pulse 
end

numSVs = length(svIdArray);
payload = 1*(rand(1,numBits) > 0.5);                         % Random payload
payload_OSR = reshape(repmat(payload,20,1),1,numBits*20);    % 50 Hz rate
hFilt = rcosdesign(alpha,6,OSR,'sqrt');                      % OSR times oversampled with alpha excess BW 
hFiltLen = length(hFilt);

J = sqrt(-1);
MAX_CODE_OFFSET = 64;
MAX_FREQ_OFFSET = 2*maxDoppFreq;
codeOffsetArray = zeros(1,numSVs); 
freqOffsetArray = zeros(1,numSVs); 
txSignal = zeros(20*numBits*1023*OSR, numSVs);
Fs = OSR*1.023e6;      % 1 msec = 1023 chips 
baseFreqOffset = MAX_FREQ_OFFSET *(rand-0.5);   % +/- 5K freq offset

for nSV = 1:numSVs
    init_g1 = ones(1,10);
    init_g2 = ones(1,10);
    codeLen = 1023;
    fbMode = ['SV',num2str(svIdArray(nSV))];
    codeOffset = floor(rand*MAX_CODE_OFFSET);   % Maximum of 64 code phase 
    freqOffset = baseFreqOffset + MAX_FREQ_OFFSET/10 *(rand-0.5);   % +/- 5K freq offset
    
    [code, symbol] = GPS_GoldSequence_generator(init_g1, init_g2, codeLen, fbMode, codeOffset);
    spreadData = kron(2*payload_OSR-1, symbol);
    temp = conv(upsample(spreadData, OSR), hFilt);
    temp1 = temp((hFiltLen-1)/2+1:end-(hFiltLen-1)/2);    
    temp2 = temp1 .* exp(J*2*pi*freqOffset/Fs*[0:length(temp1)-1]);
    txSignal(:,nSV) = transpose(temp2);                % make it a column vector
    codeOffsetArray(nSV) = codeOffset;
    freqOffsetArray(nSV) = freqOffset;
end  % End of nSV

end  % End of function
