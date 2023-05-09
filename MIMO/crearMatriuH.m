%%SRIPT PER CALIBRAR ELS DESFASES ENTRE ELS TRANSMISSORS I 1 RECEPTOR

load('data_qpsk.mat');
load('anglesSync.mat', 'anglesSync');
%FER MATRIU QUE TINGUI EN COMPTE DESFASES DEPENENT DE TRANSMISORS I
%RECEPTORS

frequenciaOperacio = 3.6e9;

dataQPSK = simb;

matriuH = zeros(4,4);
%% Preparar dades transmissor

RadioFrameLength = 10240;%40000;
RadioBasebandRate=30.72e6/2;%520.841e3;

RadioFrameTime  = (RadioFrameLength / RadioBasebandRate); % seconds
FrameCount = 1;
StopTime = RadioFrameTime*FrameCount;                                 % seconds

for transmissorUtilitzat = 1:4 %Normalment 4 antenes
    %%Transmissio
    tx = sdrtx('FMCOMMS5', ...
        'IPAddress',   '158.109.64.241', ...
        'BasebandSampleRate',      RadioBasebandRate, ...
        'CenterFrequency',          frequenciaOperacio, ...
        'ChannelMapping',          transmissorUtilitzat, ...
        'ShowAdvancedProperties',  true);
    
    transmitRepeat(tx, dataQPSK);
    pause(1);
    displayEndOfDemoMessage(mfilename)
  
    
    %% Recepcions
    for receptorUtilitzat = 1:4 %Normalment 4 antenes
        dataRebuda = rebreDades(receptorUtilitzat, StopTime, RadioFrameTime, RadioBasebandRate, frequenciaOperacio, RadioFrameLength);
        matriuH(receptorUtilitzat, transmissorUtilitzat) = trobarDesfase(dataRebuda, dataQPSK, FrameCount, RadioFrameLength);
    end
    
    %% Release general
    
    release(tx);

    displayEndOfDemoMessage(mfilename)
end


matriuHconj = conj(matriuH);
[Uconj, lambdaconj, Vconj] = svd(matriuHconj);
save('conj.mat', 'matriuH', 'matriuHconj', 'Uconj', 'lambdaconj', 'Vconj');

%% resultatFinal
resultatFinal

function resultatFinal() %Ultima transmissio on hauria d'haver sincronitzacio entre els 4 transmissors
%Serveix per evaluar si la sincronització ha estat correcta, si no, ha
%ocurregut algun cas no considerat, s'haurà de revisar funció trobarDesfase()
load('conj.mat', 'matriuH'); load('data_qpsk.mat', 'simb');

frequenciaOperacio = 3.6e9;
dataQPSK = simb;
RadioFrameLength = 10240;%40000;
RadioBasebandRate=30.72e6/2;%520.841e3;
RadioFrameTime  = (RadioFrameLength / RadioBasebandRate); % seconds
FrameCount = 1;
StopTime = RadioFrameTime*FrameCount;                     

aTransmetre = [dataQPSK dataQPSK dataQPSK dataQPSK];

tiledlayout(2,2);

for i = 1:size(matriuH, 1)
    aTransmetreSync = abs(aTransmetre).*exp((angle(aTransmetre)+angle(matriuH(i,:)))*1i);
    
    %Fer una rotacio de les dades de cada transmissor per sincronitzar-les
    
    tx = sdrtx('FMCOMMS5', ...
        'IPAddress',   '158.109.64.241', ...
        'BasebandSampleRate',      RadioBasebandRate, ...
        'CenterFrequency',          frequenciaOperacio, ...
        'ChannelMapping',          [1 2 3 4], ...
        'ShowAdvancedProperties',  true);
    
    transmitRepeat(tx, aTransmetreSync);
    pause(1);
    displayEndOfDemoMessage(mfilename)
    
    dataFinal = rebreDades(i, StopTime, RadioFrameTime, RadioBasebandRate, frequenciaOperacio, RadioFrameLength);
    release(tx)
    
    nexttile;
    scatter(real(dataFinal), imag(dataFinal), 'filled')
    title("Resultat Final Receptor "+i)
end
end
%% Funcions
function dataRebuda = rebreDades(receptorUtilitzat, StopTime, RadioFrameTime, RadioBasebandRate, frequenciaOperacio, RadioFrameLength) %Rep les dades del frame
sdrReceiver = sdrrx('FMCOMMS5', ...
        'IPAddress',   '158.109.64.241', ...
        'CenterFrequency',   frequenciaOperacio, ...
        'BasebandSampleRate',  RadioBasebandRate,...
        'GainSource', 'Manual', ...
        'Gain',30, ...
        'SamplesPerFrame', RadioFrameLength, ...
        'ChannelMapping',  receptorUtilitzat, ...
        'OutputDataType',   'double');
    
    
    numFramesinBurst = ceil(RadioBasebandRate*StopTime/RadioFrameLength);
    sdrReceiver.EnableBurstMode = true;
    sdrReceiver.NumFramesInBurst = numFramesinBurst;

try
    % Loop until the example reaches the target stop time.
    timeCounter = 0;
    
    while timeCounter < StopTime
        
        [data, valid, overflow] = sdrReceiver();
        dataRebuda = data;
        
        if (overflow > 0) && (timeCounter > 0)
            warning(message('sdrpluginbase:zynqradioExamples:DroppedSamples'));
        end
        
        if valid
            % Visualize frequency spectrum
            %spectrumScope(data);
            % Visualize in time domain
            %timeScope([real(data), imag(data)]);
            % Visualize the scatter plot
            %constellation(data);
            %scatterplot(data);
            
            % Set the limits in scopes
            %dataMaxLimit = max(abs([real(data); imag(data)]));
            %constellation.XLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];
            %constellation.YLimits = [-dataMaxLimit*1.5, dataMaxLimit*1.5];
            %timeScope.YLimits = [-dataMaxLimit*2, dataMaxLimit*2];
            timeCounter = timeCounter + RadioFrameTime;
        end
    end
    
    
catch ME
    rethrow(ME);
end
release(sdrReceiver);
end

function medianaTotal = trobarDesfase(data, dataPerComparar, FrameCount, RadioFrameLength) %Troba diferència en fase entre les dades enviades i les dades rebudes
if(FrameCount==1)
    refconv=zeros(RadioFrameLength/FrameCount,1);
    refconv(1:20)=1; %La nostra funcio transmesa comença amb 20 zeros
    
    convolucio = cconv(abs(data),refconv, RadioFrameLength/FrameCount); 
    %Volem una convolucio de la mateixa mida que el vector de dades
    
    posZeros = find(convolucio == min(convolucio)); %On la convolucio sigui el minim, estan els zeros inicials de la transmissio
    posZeros = mod(posZeros-20,RadioFrameLength); %Primer es troba l'ultim zero dels 20, ara toca posar el index al primer
    
    dataOrdenada = circshift(data,-posZeros); %Posar zeros al principi del vector
    
    desfase = mod(angle(dataPerComparar(21:end))-angle(dataOrdenada(21:end)), 2*pi);
    
    %Mod 2*pi és necessari per quan s'envien dades al segon quadrant (>2 rads) 
    %i es reben al tercer quadrant (<-2 rads) o viceversa no es crei un desfase de 0 graus
    
    medianaDesfase = median(sort(desfase)); 
    %Amb mediana dona resultats molt similars i soluciona error 
    %si el desfase oscil·la entre 0 i 2*pi (la  mitja arruina el resultat)
    
    modulDif = abs(dataOrdenada(21:end))./abs(dataPerComparar(21:end));
    medianaModul = median(sort(modulDif));
    medianaTotal = medianaModul.*exp(medianaDesfase*1i);
end
end


