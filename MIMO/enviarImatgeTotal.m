function dadesRebudesTotal = enviarImatgeTotal(dataImatge, repeticioSimbols, canals)

maxSimbolsTransmissio = floor((8388608-(length(canals)-1)-20)/2/repeticioSimbols); %El limit 8388608 ve marcat pel SDR, 
%canals-1 per poder quadrar dimensions i -20 pels zeros extres de
%sincronitzacio
simbolsAEnviar = length(dataImatge);
dadesRebudesTotal = zeros(length(dataImatge), 1);

sobrant = mod(length(dataImatge), maxSimbolsTransmissio);
if(simbolsAEnviar > maxSimbolsTransmissio)
    
    for i = 0:floor(simbolsAEnviar/maxSimbolsTransmissio)-1
        fprintf('Enviant %d de %d\n',i+1,floor(simbolsAEnviar/maxSimbolsTransmissio));
        dadesParcials = enviarImatgeQualsevullaAntena(dataImatge(1+(i*maxSimbolsTransmissio):maxSimbolsTransmissio+(i*maxSimbolsTransmissio)), repeticioSimbols, canals);
        dadesRebudesTotal(1+(i*maxSimbolsTransmissio):maxSimbolsTransmissio+(i*maxSimbolsTransmissio)) = dadesParcials;
    end
end
fprintf('Enviant fragment final\n');
ultimesDades = enviarImatgeQualsevullaAntena(dataImatge(end-sobrant+1:end), repeticioSimbols, canals);
dadesRebudesTotal(end-sobrant+1:end) = ultimesDades;
end