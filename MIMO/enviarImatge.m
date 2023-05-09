function dadesRebudes= enviarImatge(dataImatge, repeticioSimbols, canals)
%% Transmissio
load('conj.mat');

mostrarPlot = true;
repeticionsPerSimbol = repeticioSimbols;



extra = 0;

while(mod(size(dataImatge,1),length(canals))~=0)
    dataImatge(end+1)=0.7071+0.7071i; %Posat aixi perque no salti warning (necessita que s'utilitzi ":")
    extra = extra+1;
end

%Colocar les dades en els canals corresponents
dataTemp = reshape(dataImatge, [], length(canals));
data = zeros(size(dataTemp, 1), 4);
if(length(canals)~=5) %canviar a 1 si es vol que un sol canal es repliqui a tots
    data(:,canals) = dataTemp(:,1:length(canals));
else
    data(:,1) = dataTemp;
    data(:,2) = dataTemp;
    data(:,3) = dataTemp;
    data(:,4) = dataTemp;
end

%Aplicar repeticions (allargaments) de simbols i zeros inicials de
%sincroniztació
data = repelem(data, repeticionsPerSimbol, 1);
zerosPrevis = zeros(20, 4);
dataPre = vertcat(zerosPrevis, data);

RadioFrameLength =size(dataPre, 1);
RadioBasebandRate=30.72e6/2;
FrameCount = 1;

dataAEnviar = (Vconj*dataPre.').';


tx = sdrtx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
              'BasebandSampleRate',      RadioBasebandRate, ...
              'CenterFrequency',         3.6e9, ...
              'ChannelMapping',          [1 2 3 4], ...
              'ShowAdvancedProperties',  true);          
transmitRepeat(tx, dataAEnviar);
pause(1);
displayEndOfDemoMessage(mfilename)
%% Recepció

RadioFrameTime  = (RadioFrameLength / RadioBasebandRate); % seconds
StopTime        = RadioFrameTime*FrameCount;                                 % seconds

%Guany a 30 a distancia dantenes curtes, guany a 40 a llargues
sdrReceiver = sdrrx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
    'CenterFrequency',  3.6e9, ...
    'BasebandSampleRate',  RadioBasebandRate,...
    'GainSource', 'Manual', ...
    'Gain',30, ...
    'SamplesPerFrame', RadioFrameLength, ...
    'ChannelMapping',  [1 2 3 4], ...
    'OutputDataType',   'double');

numFramesinBurst = ceil(RadioBasebandRate*StopTime/RadioFrameLength);
sdrReceiver.EnableBurstMode = true;
sdrReceiver.NumFramesInBurst = numFramesinBurst;

dataTotalRebuda = zeros(RadioFrameLength*FrameCount,4);

try
    timeCounter = 0;
    iteration = 0;
    while timeCounter < StopTime
        
        [dataPRE, valid, overflow] = sdrReceiver();
        if (overflow > 0) && (timeCounter > 0)
            warning(message('sdrpluginbase:zynqradioExamples:DroppedSamples'));
        end
        
        if valid
            % Visualize frequency spectrum
            dataLambda = (Uconj'*dataPRE.').';
            data = (pinv(lambdaconj)*dataLambda.').';
            
            dataTotalRebuda(RadioFrameLength*iteration+1:RadioFrameLength*(iteration+1),:) = data;
            [dataOrdenada, dataTotalRebudaOrdenada] = trobarInici(data, dataTotalRebuda, RadioFrameLength);
            
            initialOffset = floor(repeticionsPerSimbol/2+1); 
            if(mostrarPlot)
                legendFigure = [];
                figure
                for i = 1:size(data,2)
                    %spectrumScope(data(:,1));
                    
                    % Visualize in time domain
                    %timeScope([real(data), imag(data)]);
                    
                    % Visualize the scatter plot
                    %constellation(data);
                    
                    %scatter(real(data((20+floor(repeticionsPerSimbol/2+1)):repeticionsPerSimbol:end-extra,i)), imag(data((20+floor(repeticionsPerSimbol/2+1)):repeticionsPerSimbol:end-extra,i)), 'filled');
%                     if(ismember(i, canals))
                    scatter(real(dataOrdenada(20+initialOffset:repeticionsPerSimbol:end-extra,i)), imag(dataOrdenada(20+initialOffset:repeticionsPerSimbol:end-extra,i)), 'filled');
                    hold on;
%                     else
%                     scatter(0,0);
                    hold on;
%                     end
                    legendFigure = [legendFigure, "RX"+i];
                    
                    % Set the limits in scopes
                    %                 dataMaxLimit = max(abs([real(data); imag(data)]));
                    %                 constellation.XLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];
                    %                 constellation.YLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];
                    %                 timeScope.YLimits = [-dataMaxLimit*2, dataMaxLimit*2];
                    
                end
                scatter(0,0, 'd', 'MarkerEdgeColor', [0 0 0])
                hold off;
                legendFigure = [legendFigure, "Zero"];
                legend(legendFigure)
                title("scatterplot RX trama "+(timeCounter/RadioFrameTime+1))
            end
            timeCounter = timeCounter + RadioFrameTime;
            iteration = iteration + 1;
        end
    end
catch ME
    rethrow(ME);
end


 
%dadesSenseZeros = reshape(dataOrdenada((20+floor(repeticionsPerSimbol/2+1)):repeticionsPerSimbol:end, 1:canals), [], 1);

dadesSenseZeros = reshape(dataOrdenada(20+initialOffset:repeticionsPerSimbol:end, canals), [], 1);

dadesRebudes = dadesSenseZeros(1:end-extra);

% dadesSenseZeros = reshape(dataOrdenada(21:end), [], 1); %Es treuen els 20 zeros del principi i es posa en format 1 columna
% dadesRebudes = dadesSenseZeros(1:end-(extra*repeticionsPerSimbol)); %Es treuen els valors extra del final per permetre el reshape inicial


%plotejarMultiples([dataPre, dataOrdenada], 20:50, repeticioSimbols, canals(1))


release(tx);
release(sdrReceiver);

displayEndOfDemoMessage(mfilename)
end

%% Funcions extres
function [dataOrdenada, dataTotalRebudaOrdenada] = trobarInici(data, dataTotalRebuda, RadioFrameLength) %Troba diferència en fase entre les dades enviades i les dades rebudes

    refconv=zeros(RadioFrameLength,1);
    refconv(1:20)=1; %La nostra funcio transmesa comença amb 20 zeros
    
    convolucio = cconv(abs(data(:,1)),refconv, RadioFrameLength); %Hardcodejat a receptor 1, s'haria de mirar el primer receptor del canal
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





