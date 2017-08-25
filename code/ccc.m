%
% Concordance Correlation Coefficient
%
function [pc,ci,cb,u,pr] = ccc(x1,x2)

x1 = x1(:);
x2 = x2(:);

N1 = length(x1);
N2 = length(x2);

if N1~=N2,
    error('inputs must have the same number of elements');
else
    N = N1;
end

%% sample means
mu1 = mean(x1);
mu2 = mean(x2);

%% sample variances
var1 = sum( (mu1-x1).^2 ) / N; 
var2 = sum( (mu2-x2).^2 ) / N;

%% covariance
var12 = sum( (mu1-x1).*(mu2-x2) ) / N;

%% concordance correlation coefficient
pc = 2*var12 / (var1 + var2 + (mu1 - mu2)^2 );

%% ccc variance
u = (mu1-mu2)/sqrt( sqrt(var1)*sqrt(var2) );
pr = ( sum(x1.*x2) - sum(x1)*sum(x2)/N ) / sqrt( (sum(x1.^2)-sum(x1)^2/N)*(sum(x2.^2)-sum(x2)^2/N) ) ;

varpc = (1/(N-2)) * ( ...
    ( (1-pr^2)*pc^2*(1-pc^2) )/(pr^2) ...
  + ( 2*pc^3*(1-pc)*u^2) / pr ...
  - (pc^4)*u^4/(2*pr^2) ...
  );

%% asymptotic variance after applying Z-transformation

% Chinchilli, 1996
% varz = (1/(N-2)) * ( ...
%     ( (1-pr^2)*pc^2 ) / ( (1-pc^2)*pr^2 )...
%   + ( 4*pc^3*(1-pc)*u^2 ) / ( pr*(1-pc^2)^2 ) ...
%   - ( 2*(pc^4)*u^4 )/( (pr^2)*(1-pc^2)^2 ) ...
%   ); 

% crawford, 2007
varz = (1/(N-2)) * ( ...
    ( (1-pr^2)*pc^2 ) / ( (1-pc^2)*pr^2 )...
  + ( 2*pc^3*(1-pc)*u^2 ) / ( pr*(1-pc^2)^2 ) ...
  - ( (pc^4)*u^4 )/( 2*(pr^2)*(1-pc^2)^2 ) ...
  );

%% 95% confidence interval interval values
zval = 1.959964;
tval = tinv(0.975,N-2);

%% Z transformation
pcz = 0.5 * log( (1+pc)/(1-pc) );

zL = pcz - tval*sqrt(varz);
zU = pcz + tval*sqrt(varz);

%% transform back
pc = (exp(2*pcz)-1)/(exp(2*pcz)+1);
ci = [ (exp(2*zL)-1)/(exp(2*zL)+1) (exp(2*zU)-1)/(exp(2*zU)+1)];

%% bias correction factor
cb = pc/pr;