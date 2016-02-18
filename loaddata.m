% this functions loads data files and finds r offsets 
function [rexp2,pexp2,rofst,rro,phsfnco,aexp2,aell2] = loaddata
global dfexp2 ds atenter


for uu=1:ds(2)

eval(['load C:\mfiles\73115\LANL2P' num2str(uu) '.mat'])
eval(['load C:\mfiles\73115\LANL2R' num2str(uu) '.mat'])
eval(['load C:\mfiles\73115\LANL2A' num2str(uu) '.mat'])
mltplr=24;              

nantest=isnan(AxPos);
if nantest(1) == 1
    AxPos(1)=-AxPos(31);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find r offset by curve fitting central portion of phase pofile with
% polyfit.  Ideally this would be another fitting paramter but this would
% invove a 3 parameter fitting space.  The r offset could be found by
% fitting a single paramter but this would require acurate knowledge of the
% thermal parameters. 

[c6,c7]=size(phs);
midpt=round(c7/2);
AxPos=-AxPos; % once Zilongs code is fixed we can get rid of this
AxPos=AxPos*mltplr;
rfit=AxPos(midpt-4:midpt+4); 
phsfit=phs(midpt-4:midpt+4);
rmn=min(rfit);
rmx=max(rfit);
delr=(rmx-rmn)/100;
rr=[rmn:delr:rmx];
p=polyfit(rfit,phsfit,2);
phsfnc=p(1)*rr.^2+ p(2)*rr+p(3);
[x4,y4]=max(phsfnc);
[x5,y5]=max(phs);
rofs=rr(y4); % note I did not use ofst1 - no need with this formulation

% create variables to pass to output
rofst(uu)=rofs;
rro(uu,:)=rr;
phsfnco(uu,:)=phsfnc;

% max(phsfnc) is the offset value of the curve fit line.  using this offset
% value will leave your data points at r=0 scattered about zero

if uu<7
phs=phs-max(phsfnc);
end

rexp2(:,uu)=AxPos-rofs;
pexp=phs;
pexp2(:,uu)=pexp;


aexp=mag/max(mag);
aexp2(:,uu)=aexp;

aell1=pexp;
if atenter == 1
aell1(32:62)=aexp;
end
aell2(:,uu)=aell1;
clear aell1

% this next section is put in to weight low and high freq equally - df goes
% into the calculation of the sum of the square of the errors
g=abs(min(pexp));
dfexp2(:,uu)=ones(c7,1)/g;
end

