function twoBits = oneBitToTwoBits(data)

dataAux = reshape(data, 2, []);
dataAux = fi(dataAux(:, 1:end), 0, 1);
twoBits = reshape(bitconcat(dataAux(1, 1:end), dataAux(2, 1:end)), [], 1);

end