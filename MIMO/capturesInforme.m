%% Transmissió
disp('Començant transmissió')

load('data_qpsk.mat'); 

RadioFrameLength = 10240;%40000;
RadioBasebandRate=30.72e6/2;%520.841e3;
FrameCount = 1;

tx = sdrtx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
              'BasebandSampleRate',      RadioBasebandRate, ...
              'CenterFrequency',         3.6e9, ...
              'ChannelMapping',          1, ...
              'ShowAdvancedProperties',  true);
          
transmitRepeat(tx, simb);
pause(1);
displayEndOfDemoMessage(mfilename)

%% Recepció

RadioFrameTime  = (RadioFrameLength / RadioBasebandRate); % seconds
StopTime        = RadioFrameTime*FrameCount;                                 % seconds

sdrReceiver = sdrrx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
    'CenterFrequency',  3.6e9, ...
    'BasebandSampleRate',  RadioBasebandRate,...
    'GainSource', 'Manual', ...
    'Gain',40, ...
    'SamplesPerFrame', RadioFrameLength, ...
    'ChannelMapping',  1, ...
    'OutputDataType',   'double');

numFramesinBurst = ceil(RadioBasebandRate*StopTime/RadioFrameLength);
sdrReceiver.EnableBurstMode = true;
sdrReceiver.NumFramesInBurst = numFramesinBurst;

dataTotalRebuda = zeros(RadioFrameLength*FrameCount,4);

try
    timeCounter = 0;
    iteration = 0;
    while timeCounter < StopTime
        
        [data, valid, overflow] = sdrReceiver();
        if (overflow > 0) && (timeCounter > 0)
            warning(message('sdrpluginbase:zynqradioExamples:DroppedSamples'));
        end
        
        if valid         
            %tmp_figure = figure(1);
            scatter(real(data), imag(data), 'filled');
            hold on
            scatter(real(data(1:5:end)), imag(data(1:5:end)), 'filled');
            hold off
            %saveas(tmp_figure, "./../captures/recepcio_no_sincronitzada.png");
            
            timeCounter = timeCounter + RadioFrameTime;
        end
    end
catch ME
    rethrow(ME);
end
%% Trobar parametres escala

[dataOrdenada, dataTotalRebudaOrdenada] = trobarInici(data, dataTotalRebuda, RadioFrameLength);

A = mean(abs(dataOrdenada(21:end)));

desfase = mod(angle(simb(21:end))-angle(dataOrdenada(21:end)), 2*pi);
phi = median(sort(desfase));

release(tx);
release(sdrReceiver);

displayEndOfDemoMessage(mfilename)
%% Transmissio sincronitzada

tx = sdrtx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
              'BasebandSampleRate',      RadioBasebandRate, ...
              'CenterFrequency',         3.6e9, ...
              'ChannelMapping',          1, ...
              'ShowAdvancedProperties',  true);
          
dataAEnviar = abs(simb)*0.2.*exp((angle(simb)+phi)*1i);
% dataAEnviar = [1, -1, 1i, -1i].';
% dataAEnviar = repmat(dataAEnviar, 100, 1);
% dataAEnviar = repelem(dataAEnviar, 10);
% dataAEnviar(1:20) = 0;
% dataAEnviar = abs(dataAEnviar).*exp((angle(dataAEnviar)+phi)*1i);
transmitRepeat(tx, dataAEnviar);
pause(1);
displayEndOfDemoMessage(mfilename)
%% Recepcio sincronitzada


sdrReceiver = sdrrx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
    'CenterFrequency',  3.6e9, ...
    'BasebandSampleRate',  RadioBasebandRate,...
    'GainSource', 'Manual', ...
    'Gain',40, ...
    'SamplesPerFrame', RadioFrameLength, ...
    'ChannelMapping',  1, ...
    'OutputDataType',   'double');

numFramesinBurst = ceil(RadioBasebandRate*StopTime/RadioFrameLength);
sdrReceiver.EnableBurstMode = true;
sdrReceiver.NumFramesInBurst = numFramesinBurst;

dataTotalRebuda = zeros(RadioFrameLength*FrameCount,4);

try
    timeCounter = 0;
    iteration = 0;
    while timeCounter < StopTime
        
        [data, valid, overflow] = sdrReceiver();
        data = data;
        dataAux = abs(data).*exp((angle(data)+phi)*1i);
        if (overflow > 0) && (timeCounter > 0)
            warning(message('sdrpluginbase:zynqradioExamples:DroppedSamples'));
        end
        
        if valid         
            %tmp_figure = figure(1);
            scatter(real(data), imag(data), 'filled');
%             hold on
%             scatter(real(dataAux/A), imag(dataAux/A), 'filled');
%             hold on
%             scatter(real(dataAEnviar), imag(dataAEnviar), 'filled');
            hold off
            %saveas(tmp_figure, "./../captures/recepcio_sincronitzada.png");
            timeCounter = timeCounter + RadioFrameTime;
        end
    end
catch ME
    rethrow(ME);
end


%% Tancar SDR
release(tx);
release(sdrReceiver);

displayEndOfDemoMessage(mfilename)

%% Funcions

function [dataOrdenada, dataTotalRebudaOrdenada] = trobarInici(data, dataTotalRebuda, RadioFrameLength) %Troba diferència en fase entre les dades enviades i les dades rebudes

    refconv=zeros(RadioFrameLength,1);
    refconv(1:20)=1; %La nostra funcio transmesa comença amb 20 zeros
    
    convolucio = cconv(abs(data(:,1)),refconv, RadioFrameLength);
    %Volem una convolucio de la mateixa mida que el vector de dades
    
    posZeros = find(convolucio == min(convolucio)); %On la convolucio sigui el minim, estan els zeros inicials de la transmissio
    posZeros = mod(posZeros-20,RadioFrameLength); %Primer es troba l'ultim zero dels 20, ara toca posar el index al primer
    
%     dataOrdenada = zeros(RadioFrameLength,4);
%     dataOrdenada(:,1) = circshift(data(:,1),-posZeros); %Posar zeros al principi del vector
%     dataOrdenada(:,2) = circshift(data(:,2),-posZeros);
%     dataOrdenada(:,3) = circshift(data(:,3),-posZeros);
%     dataOrdenada(:,4) = circshift(data(:,4),-posZeros);

    dataOrdenada = circshift(data, -posZeros);
    dataTotalRebudaOrdenada = circshift(dataTotalRebuda, -posZeros);
end
