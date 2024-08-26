clear all; close all;

LGM_expo = [0,1,2,3];

Burial_age = [390,410,424,436];
err = [70,80,90,92];

figure;
% errorbar(Burial_age,LGM_expo,err,'horizontal','S');

errorbar(Burial_age,LGM_expo,err,'horizontal',"S","MarkerSize",10,...
    "MarkerEdgeColor","blue","MarkerFaceColor",[0.65 0.85 0.90]);
axis([0 1000 -0.5 4])
set(gca,'ytick',[0 1 2 3 4]);
set(gca,'yticklabels',[0 1 2 3 4]);
xlabel('Burial age (ka)');
ylabel('Total LGM exposure (ka)');
box on



return

x = 1:10:100;
y = [20 30 45 40 60 65 80 75 95 90];
err = [4 3 5 3 5 3 6 4 3 3];
errorbar(x,y,err,"both","o")

x = linspace(0,10,15);
y = sin(x/2);
err = 0.3*ones(size(y));
errorbar(x,y,err,"-s","MarkerSize",10,...
    "MarkerEdgeColor","blue","MarkerFaceColor",[0.65 0.85 0.90])










