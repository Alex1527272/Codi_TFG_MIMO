%% Preparació matrius

if ~exist('lambda2','var')
    calcularDesfase
end

%% Transmissió

load('data_qpsk.mat'); load('anglesSync2.mat', 'anglesSync2'); load('inversa2.mat');

RadioFrameLength = 10240;%40000;
RadioBasebandRate=30.72e6/2;%520.841e3;

transmissio = [1 1];

simb1 = zeros(RadioFrameLength,1);
simb2 = zeros(RadioFrameLength,1);



% simb2(21:end) = circshift(simb(21:end), 5000);



% simb1 = ones(RadioFrameLength, 1)*(0.7071+0.7071i);
% simb2 = ones(RadioFrameLength, 1)*(-0.7071-0.7071i);
% simb3 = ones(RadioFrameLength, 1)*(-0.7071+0.7071i);
% simb4 = ones(RadioFrameLength, 1)*(0.7071-0.7071i);

zynqRadioQPSKTransmitDataTest = [simb simb].*transmissio;

simbolsEnviats = assignarSimbols(zynqRadioQPSKTransmitDataTest, transmissio);
simbolsEnviatsFinals = seleccionarSimbols(simbolsEnviats);

zynqRadioQPSKTransmitDataTestPost = (VInversa2*zynqRadioQPSKTransmitDataTest.').';



tx = sdrtx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
              'BasebandSampleRate',      RadioBasebandRate, ...
              'CenterFrequency',         3.6e9, ...
              'ChannelMapping',          [1 2], ...
              'ShowAdvancedProperties',  true);
          
transmitRepeat(tx, zynqRadioQPSKTransmitDataTestPost);
pause(1);
displayEndOfDemoMessage(mfilename)

%% Recepció

RadioFrameTime  = (RadioFrameLength / RadioBasebandRate); % seconds
FrameCount = 1;
StopTime        = RadioFrameTime*FrameCount;                                 % seconds

sdrReceiver = sdrrx('FMCOMMS5', ...
              'IPAddress',   '158.109.64.241', ...
    'CenterFrequency',  3.6e9, ...
    'BasebandSampleRate',  RadioBasebandRate,...
    'GainSource', 'Manual', ...
    'Gain',40, ...
    'SamplesPerFrame', RadioFrameLength, ...
    'ChannelMapping',  [1 2], ...
    'OutputDataType',   'double');

numFramesinBurst = ceil(RadioBasebandRate*StopTime/RadioFrameLength);
sdrReceiver.EnableBurstMode = true;
sdrReceiver.NumFramesInBurst = numFramesinBurst;

modulsRebuts = zeros(1,2);
try
    timeCounter = 0;
    
    while timeCounter < StopTime
        
        [dataPRE, valid, overflow] = sdrReceiver();
        if (overflow > 0) && (timeCounter > 0)
            warning(message('sdrpluginbase:zynqradioExamples:DroppedSamples'));
        end
        
        if valid
            % Visualize frequency spectrum
            dataLambda = (UInversa2'*dataPRE.').';
            data = (pinv(lambdaInversa2)*dataLambda.').';
            figure
            for i = 1:size(data,2)
                %spectrumScope(data(:,1));
                
                % Visualize in time domain
                %timeScope([real(data), imag(data)]);
               
                % Visualize the scatter plot
                %constellation(data);
                scatter(real(data(:,i)), imag(data(:,i)), 'filled');
                hold on;
                
                % Set the limits in scopes
%                 dataMaxLimit = max(abs([real(data); imag(data)]));
%                 constellation.XLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];
%                 constellation.YLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];
%                 timeScope.YLimits = [-dataMaxLimit*2, dataMaxLimit*2];
                modulsRebuts(i) = mean(abs(data(:,i)));
            end
            scatter(0,0, 'd', 'MarkerEdgeColor', [0 0 0])
            hold off;
            legend('RX1', 'RX2','RX3', 'Zero')
            title("scatterplot RX trama "+(timeCounter/RadioFrameTime+1))
            timeCounter = timeCounter + RadioFrameTime;
        end
    end
catch ME
    rethrow(ME);
end

dataOrdenada = trobarInici(data, FrameCount, RadioFrameLength);

simbolsRebuts = assignarSimbols(dataOrdenada, transmissio);
simbolsRebutsFinals = seleccionarSimbols(simbolsRebuts);
%% Resultat final comparat amb valors enviats

simbolsIncorrectes = size(nonzeros(simbolsRebuts-simbolsEnviats), 1); %Cantitat de simbols rebuts que no coincideixen
simbolsIncorrectesFinals = size(nonzeros(simbolsRebutsFinals-simbolsEnviatsFinals), 1); %Cantitat de simbols decidits que no coincideixen


release(tx);
release(sdrReceiver);

displayEndOfDemoMessage(mfilename)
%% Funcions

function dataOrdenada = trobarInici(data, FrameCount, RadioFrameLength) %Troba diferència en fase entre les dades enviades i les dades rebudes
if(FrameCount==1)
    refconv=zeros(RadioFrameLength/FrameCount,1);
    refconv(1:20)=1; %La nostra funcio transmesa comença amb 20 zeros
    
    convolucio = cconv(abs(data(:,1)),refconv, RadioFrameLength/FrameCount);
    %Volem una convolucio de la mateixa mida que el vector de dades
    
    posZeros = find(convolucio == min(convolucio)); %On la convolucio sigui el minim, estan els zeros inicials de la transmissio
    posZeros = mod(posZeros-20,RadioFrameLength); %Primer es troba l'ultim zero dels 20, ara toca posar el index al primer
    
    dataOrdenada = zeros(10240,3);
    dataOrdenada(:,1) = circshift(data(:,1),-posZeros); %Posar zeros al principi del vector
    dataOrdenada(:,2) = circshift(data(:,2),-posZeros);


    
end
end

function simbols = assignarSimbols(data, transmissio)
%El que es fa en aquesta funcio es molt "especialet". Si no s'enten es
%recomana crear una nova funció que assigni simbols als angles de recepció
simbols = ones(10240,2).*transmissio;
simbols(1:20, :) = 0; %Comentar si no hi ha 20 zeros al principi

anglesMatrix = angle(data);

simbols = simbols.*((anglesMatrix>pi/2)+1); %Si angle és superior a pi/2 vol dir que estem al segon quadrant (real negatiu, imaginari positiu), per tant assignem un 2 
simbols = simbols.*((anglesMatrix<(-pi/2))*2+1); %Si angle és inferior a -pi/2 vol dir que estem al tercer quadrant (real i imaginari negatius)
simbols = simbols.*((anglesMatrix<0 & anglesMatrix>(-pi/2))*3+1); %Si angle entre 0 i -pi/2 estem a quart quadrant (real positiu, imaginari negatiu)    

%Com que simbols comença a 1, la resta de valors seran els del primer
%quadrant
end
function simbolsFinals = seleccionarSimbols(simbols)
    simbolsFinals = zeros(1024, 2);
    for i = 0:1023
        simbolsFinals(i+1,:) = mode(simbols((i*10)+1:(i*10)+10, :)); %Toba el valor majoritari de cada 10 simbols
    end
    
end