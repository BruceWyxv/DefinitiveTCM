% PARS is a vector containing the unknown parameters that will define the
% search space. 
% PARS2 is a vector containing the know parameters
% function [atll3] = TWM(pars)
function [atll3] = TWM(pars)
global kf Df rexp2 df nuvector ds atenter parmenter


if parmenter == 1
    ks=pars(1);
    Ds=pars(2);
    Re=pars(3);
    Rth=pars(4);
    Rth=abs(Rth);
elseif parmenter ==2
    ks=pars(1);
    Ds=pars(2);
    Re=pars(3);
    Rth=0;
elseif parmenter ==3
    kf=pars(1);
    Df=pars(2);
    Re=pars(3);
    Rth=pars(4);
    ks=1.089;
    Ds=.605e-6;
end


for uu=1:ds(2)
nu=nuvector(uu);  
omega=2*pi*nu;          % circular frequency
P0=1;                   % absorbed laser power
alphaf=5e9;             % absorption coefficient


% Relevant thermal wavenumbers wavelengths
q0=ks./(df.*kf);
q1=sqrt(i.*omega./Df+q0.^2./2.*(1-sqrt(1-4.*i.*omega./(Ds.*q0.^2).*(1-Ds./Df))));
qs=sqrt(i*omega/Ds);
qf=sqrt(i*omega/Df);
lambdas=2*pi/real(qs);
lambdaf=2*pi/real(qf);
lambda1=2*pi/real(q1);

% Setup y array - yymax is tied to thermal wavelength - we get into
% problems when we chose yymax and frequency independently (especially for
% large yymax and large frequency).  By tying the two together we avoid
% this issue
% y0=0;
% ess=.9333*log10(nu)-1.666;
% %yymax=1/real(q1)*1e6;
% [c3,c4]=size(pexp);
% step2=1.045; 
% yymax=c4*step2-rofs;
% yy=[rofs:step2:yymax]*1e-6;

yy=rexp2(:,uu)*1e-6;
[c1,c2]=size(yy');
y0=0;

% Setup p array
P0=1;
pmax=10/(2.0e-6);
delp=pmax/1000;
p=[0:delp:pmax];

% parameters from writeup on 3-19-14
nf=sqrt(p.^2+i*omega/Df);
ns=sqrt(p.^2+i*omega/Ds);
F=P0*alphaf*exp(-p.^2*Re^2/4)/(2*pi*kf);
E=F./(alphaf^2-p.^2-i*omega/Df);
A=-E.*(-alphaf.*kf.*nf-alphaf.*kf.*ns.*ks.*Rth.*nf-alphaf.*ns.*ks+alphaf.*kf.*exp(-alphaf.*df-nf.*df).*nf-exp(-alphaf.*df-nf.*df).*nf.*ns.*ks+exp(-alphaf.*df-nf.*df).*nf.*kf.*ns.*ks.*Rth.*alphaf)./nf./(-nf.*kf-nf.*kf.*ns.*ks.*Rth-ns.*ks+nf.*kf.*exp(-2.*nf.*df)+nf.*kf.*ns.*ks.*Rth.*exp(-2.*nf.*df)-ns.*ks.*exp(-2.*nf.*df));
B=-E.*(alphaf.*kf.*exp(-alphaf.*df).*nf-exp(-alphaf.*df).*nf.*ns.*ks+exp(-alphaf.*df).*nf.*kf.*ns.*ks.*Rth.*alphaf-nf.*kf.*exp(-nf.*df).*alphaf-alphaf.*kf.*ns.*ks.*Rth.*exp(-nf.*df).*nf+alphaf.*ns.*ks.*exp(-nf.*df)).*exp(-nf.*df)./nf./(-nf.*kf-nf.*kf.*ns.*ks.*Rth-ns.*ks+nf.*kf.*exp(-2.*nf.*df)+nf.*kf.*ns.*ks.*Rth.*exp(-2.*nf.*df)-ns.*ks.*exp(-2.*nf.*df));
int=p.*(A+B+E);

% for loop for thermal wave solution at each y step
for ii=1:c2
    y=abs(yy(ii));
    pre3=1;
    integrand=besselj(0,p*(y-y0)).*int;
    T(ii)=-pre3.*trapz(integrand)/(1/delp);
end

% get value at y=0 for offset calculation
integrand0=besselj(0,p*(0-y0)).*int;
T0=-pre3.*trapz(integrand0)/(1/delp);
    
tht=angle(T);%unwrap(2*atan(imag(T)./real(T)))/2;
tht0=angle(T0);%atan(imag(T0)./real(T0));
ampl=abs(T);

% take into account phase jumps of pi
deltht=round(abs(tht0-max(tht))/pi);
tht0=tht0+pi*deltht;

if uu<7
tht=tht-tht0;
end

ampt=abs(T)/max(abs(T));
%tht=unwrap(tht);
tht=tht*180/pi;
tht2(:,uu)=tht;

atll1=tht;
if atenter == 1
atll1(32:62)=ampt;
end
atll2(:,uu)=atll1;

clear atll1

end
tht3=tht2(:);
atll3=atll2(:);


