function oneBit = twoBitsToOneBit(data)

vectorBinari = decimalToBinaryVector(double(data));


transpost = vectorBinari';

oneBit = reshape(transpost, [], 1);

end