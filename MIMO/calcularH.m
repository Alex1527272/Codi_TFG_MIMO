load('anglesSync.mat');
matriuH = abs(anglesSync).*exp(angle(anglesSync)*1i);
[U, lambda, V] = svd(matriuH);
matriuHmodul = abs(anglesSync);
save('matriuH.mat', 'matriuH', 'U', 'lambda', 'V', 'matriuHmodul');


load('inversa.mat');
matriuHInversa = 1./matriuH;
matriuHModulInversa = 1./matriuHmodul;
[UInversa, lambdaInversa, VInversa] = svd(matriuHInversa);
save('inversa.mat', 'matriuH', 'matriuHInversa', 'UInversa', 'lambdaInversa', 'VInversa', 'matriuHModulInversa');

load('conj.mat');
matriuHconj = conj(matriuH);
[Uconj, lambdaconj, Vconj] = svd(matriuHconj);
save('conj.mat', 'matriuH', 'matriuHconj', 'Uconj', 'lambdaconj', 'Vconj');

load('herm.mat');
matriuHherm = matriuH';
[Uherm, lambdaherm, Vherm] = svd(matriuHherm);
save('herm.mat', 'matriuH', 'matriuHherm', 'Uherm', 'lambdaherm', 'Vherm');