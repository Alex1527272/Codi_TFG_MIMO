load('matriuH');

% x = [0.7071+0.7071i -0.7071-0.7071i -0.7071+0.7071i 0.7071-0.7071i].';
% xPost = Vconj*x;

% simb1 = ones(10240, 1)*(0.7071+0.7071i);
% simb2 = ones(10240, 1)*(-0.7071-0.7071i);
% simb3 = ones(10240, 1)*(-0.7071+0.7071i);
% simb4 = ones(10240, 1)*(0.7071-0.7071i);
% 
zerosSimb = zeros(10240,1);
x = [simb zerosSimb zerosSimb zerosSimb].';

xPost = V*x;

yPre = matriuH*xPost;
yLambda = U'*yPre;
y = pinv(lambda)*yLambda;

