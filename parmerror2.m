% this mfile fits Ds, Re and ks using fminsearch.m.  the standard error associated with
% this is also cacluated using nonlinear regression.  The error bars are given by ablower 
% and abupper and the fitted values are given by parfinal 
tic
clear
clear global
% input known parameters as global variables
global kf Df pexp2 rexp2 dfexp2 df nuvector ds atenter parmenter

% do you want to calculate the standard deviation 1-yes, 2-no?
sdenter=2;

% fit amplitude and theta -1 or just theta -2
atenter=1;

% which parms are we fitting (ks, Ds, Re, Rth -1) or (ks, Ds, Re -2) or
% (kf, Df, Re, Rth - 3)
parmenter=2;

if parmenter == 1
    nuvector=[1e3 2e3 5e3 10e3 20e3 50e3 100e3];
elseif parmenter == 2
    nuvector=[1e3 2e3 5e3 10e3 20e3 50e3];
elseif parmenter == 3
    nuvector=[1e3 2e3 5e3 10e3 20e3 50e3 100e3];
end


rhof=19300;
Cf=128;

df=137e-9;
if parmenter ~= 3 
kf=160;
Df=kf/(rhof*Cf);
end

ds=size(nuvector);
[rexp2,pexp2,rofst,rro,phsfnco,aexp2,aell2]=loaddata;

% make data into 1D array
pexp3=pexp2(:);
dfexp3=dfexp2(:);
aell3=aell2(:);

    

% setup call to fminsearch
sumofsquares = @(parstart) sum((TWM(parstart)-aell3).^2);

if parmenter == 1
parstart = [9.2 3.4e-6 2e-6 3e-8];
fit=fminsearch(sumofsquares,parstart);
ks=fit(1);
Ds=fit(2);
Re=fit(3);
Rth=fit(4);
parfinal=[ks, Ds, Re, Rth];

elseif parmenter == 2
parstart = [9.2 3.4e-6 2e-6 ];
fit=fminsearch(sumofsquares,parstart);
ks=fit(1);
Ds=fit(2);
Re=fit(3);
parfinal=[ks, Ds, Re];

elseif parmenter == 3
parstart = [100 4e-5 2e-6 3e-8];
fit=fminsearch(sumofsquares,parstart);
kf=fit(1);
Df=fit(2);
Re=fit(3);
Rth=fit(4);
parfinal=[kf, Df, Re, Rth];
end




% for plot routine we also need to reshape output of TWM
tht=TWM(parfinal);
[c1,c2]=size(aell2);
tht2=reshape(tht,c1,c2);


% calculate standard deviation
if sdenter==1
% degrees of freedom in the problem
dof=c2*(c1-2);

% standard deviation of the residuals
sdr = sqrt(sum((TWM(parfinal)-pexp3).^2)/dof);

% jacobian matrix
J = jacobianest(@TWM,parfinal);


% I'll be lazy here, and use inv. Please, no flames,
% if you want a better approach, look in my tips and
% tricks doc.
Sigma = sdr^2*inv(J'*J);

% Parameter standard errors
se = sqrt(diag(Sigma))';

% which suggest rough confidence intervalues around
% the parameters might be...
abupper = parfinal + 2*se;
ablower = parfinal - 2*se;

parmsfinal(:,1)=abupper;
parmsfinal(:,2)=ablower;
parmsfinal(:,3)=parfinal;
end

% plot routine
if atenter == 1
figure(1)
clf
plot(rexp2,pexp2,'.','MarkerSize',16)
hold
plot(rexp2,tht2(1:c1/2,:),'LineWidth',2)
set(gca,'fontsize',24)

figure(2)
clf
plot(rexp2,aell2(c1/2+1:c1,:),'.','MarkerSize',16)
hold
plot(rexp2,tht2(c1/2+1:c1,:),'LineWidth',2)
set(gca,'fontsize',24)

figure(3)
for uu=1:c2
plft=polyfit(rexp2(c1/2-10:c1/2,uu)*1e-6,tht2(c1/2-10:c1/2,uu)*pi/180,1);
req(uu)=-plft(1);
end
clf
loglog(nuvector,req,'.','MarkerSize',16)
hold
omega=2.*pi.*nuvector;
wvnf=sqrt(omega./(2.*Df));
wvns=sqrt(omega./(2.*Ds));


q0=ks./(df.*kf);
q1=sqrt(i.*omega./Df+q0.^2./2.*(1-sqrt(1-4.*i.*omega./(Ds.*q0.^2).*(1-Ds./Df))));
q0=ks./(df.*kf);
%loglog(nuvector,real(q1),'r','LineWidth',2)
loglog(nuvector,real(wvnf),'k','LineWidth',2)
loglog(nuvector,real(wvns),'k','LineWidth',2)
set(gca,'fontsize',24)

elseif atenter == 2
figure(1)
clf
plot(rexp2,pexp2,'k.','Markersize',20,'LineWidth',2,'Color',[.4 .4 .4])
hold
plot(rexp2,tht2(1:c1,:),'k','LineWidth',2)
set(gca,'fontsize',24)


figure(2)
for uu=1:c2
plft=polyfit(rexp2(c1-10:c1,uu)*1e-6,tht2(c1-10:c1,uu)*pi/180,1);
req(uu)=-plft(1);
end
clf
loglog(nuvector,req,'.','MarkerSize',16)
hold
omega=2.*pi.*nuvector;
wvnf=sqrt(omega./(2.*Df));
wvns=sqrt(omega./(2.*Ds));


q0=ks./(df.*kf);
q1=sqrt(i.*omega./Df+q0.^2./2.*(1-sqrt(1-4.*i.*omega./(Ds.*q0.^2).*(1-Ds./Df))));
q0=ks./(df.*kf);
loglog(nuvector,real(q1),'r','LineWidth',2)
loglog(nuvector,real(wvnf),'k','LineWidth',2)
loglog(nuvector,real(wvns),'r','LineWidth',2)
set(gca,'fontsize',24)
end
parfinal
toc