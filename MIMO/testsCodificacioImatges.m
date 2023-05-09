if ~exist('firstExecution','var')
    disp('Primera execució')
    crearMatriuH
    firstExecution = clock;
    
end
if etime(clock, firstExecution) > 1200 %Recalcular matriuH cada 20 minuts
    disp('Recalculant Matriu H (> 20 mins)')
    crearMatriuH
    firstExecution = clock;
end


%% Preparar dades imatge

disp('Calculant vector a enviar')

imatge = "lena.jpg";

dataImatge = imread("images/"+imatge);

histogramaSimbols = histcounts(dataImatge, 2^8);

freqsSimbols = histogramaSimbols/sum(histogramaSimbols);

simbols = 0:2^8-1;

dict = huffmandict(simbols, freqsSimbols);

% image(dataImatge);

dataEnVector = reshape(dataImatge,[], 1);

dataAEnviar = cast(huffmanenco(dataEnVector, dict), "logical");
extra = 0;
if(mod(size(dataAEnviar,1),2)~=0)
    dataAEnviar(end+1)=cast(0, "logical");
    extra = 1;
end

qpskmod = comm.QPSKModulator('BitInput',true); %Indiquem que els valors de entrada son binaris

dataFinal = qpskmod(dataAEnviar);

%% Fer transmissio i recepcio
disp('Començant transmissió')

repeticioSimbols = 5;

canalsAUtilitzar = [1, 2, 3]; %Canals a utilitzar en posicions separades d'un vector
%Exemple: [1], [2], [1,3], [1,4], [2,3,4], ...
%Investigar error amb 2 repeticions 1 canal, pero no amb 3 repeticions 1 canal (quan trama / 2)

%Investigar incorrecte amb 4 repeticions 1 canal, pero no amb 3 repeticions 1 canal

%Amb 1 canal 2 repeticions, a vegades sembla que ho fa perfecte, pero torna
%24000 bits erronis


dadesRebudes = enviarImatgeTotal(dataFinal, repeticioSimbols, canalsAUtilitzar); %Hauria de ser igual a dataFinal
% dadesRebudes = enviarImatge(dataFinal, repeticioSimbols, nombreDeCanals); %Hauria de ser igual a dataFinal

%% Demodulació
disp('Començant demodulacio')

qpskdemod = comm.QPSKDemodulator('BitOutput',true);

demodulacio = qpskdemod(dadesRebudes); %Hauria de ser igual a dataAEnviar
% 
% demodulacio2bits = oneBitToTwoBits(demodulacio);
% dadesATractar = reshape(demodulacio2bits, repeticioSimbols, []); %Coloquem cada simbol i les seves repeticions en la mateixa columna
% dadesDecidides = reshape(mode(dadesATractar, 1), [], 1); %Es mira quin es el valor majoritari de cada columna per decidir amb quin valor ens quedem i coloquem en format una columna
% demodulacioDecidida = twoBitsToOneBit(dadesDecidides);
% 
BitsIncorrectes = size(nonzeros(demodulacio-dataAEnviar),1);
tasaErrorBit = BitsIncorrectes/size(demodulacio, 1);

if(extra == 1)
    demodulacio = demodulacio(1:end-1);
end

decodificacio = huffmandeco(demodulacio, dict); %Hauria de ser igual a dataEnVector
%ERROR QUE QUAN NO ES REP 100% EL MATEIX, LA DECODIFICACIO RETORNA UNA
%DIMENSIO DIFERENT, PER TANT NO ES POT FER EL RESHAPE
%INVESTIGAR ALGUN CODI CORRECTOR

imatgeFinal = uint8(reshape(decodificacio(1:length(dataEnVector)), 630, 630, []));
figure;
image(imatgeFinal);

recepcioCorrecte = boolean(isequal(imatgeFinal, dataImatge)); %0 = FALSE, 1 = TRUE
