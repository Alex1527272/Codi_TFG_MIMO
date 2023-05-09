load('anglesSync2.mat');
matriuH2 = exp(anglesSync2*1i);
[U2, lambda2, V2] = svd(matriuH2);
save('matriuH2.mat', 'matriuH2', 'U2', 'lambda2', 'V2');


load('inversa2.mat');
matriuHInversa2 = 1./matriuH2;
[UInversa2, lambdaInversa2, VInversa2] = svd(matriuHInversa2);
save('inversa2.mat', 'matriuHInversa2', 'UInversa2', 'lambdaInversa2', 'VInversa2');

