
clear all; close all;

filename = 'Diring_Cosmo_Depths.xlsx'; 
T = xlsread(filename);

N10 = T(:,1);
N10_unc = T(:,2);
N26 = T(:,3);
N26_unc = T(:,4);
R26_10 = T(:,5);
Depths = T(:,6);

filename2 = 'Diring_Input_2_High_plot.xlsx'; 
T_High = xlsread(filename2);
N10_High = T_High(:,1);
N26_High = T_High(:,3);
R26_10_High = T_High(:,6);
Depths_High = T_High(:,7);


figure;
subplot(2,1,1)
hold on
plot(Depths,N10,'Or');
plot(Depths_High,N10_High,'Ob');
ylabel('10Be concentration (at/g)');
subplot(2,1,2)
hold on
plot(Depths,R26_10,'Or');
plot(Depths_High,R26_10_High,'Ob');
xlabel('Depths (cm)');
ylabel('26Al/10Be ratio');


load("LR04_stack.txt");
LR04_age = LR04_stack(:,1);
LR04_d18O = LR04_stack(:,2);

k = -4;

plot_LR04_d18O = -((LR04_d18O-mean(LR04_d18O)+k)./(2*std(LR04_d18O)));

load("Elgygytgyn_SiTi.txt");
age_Elgy = Elgygytgyn_SiTi(:,1);
SiTi_Elgy = Elgygytgyn_SiTi(:,2);

Burial_age = 390;
Burial_age_unc = 70;



x = [0:1:3000];
y = normpdf(x,Burial_age,Burial_age_unc);

figure;
plot(age_Elgy,SiTi_Elgy,'-k');
yyaxis right
plot(x,y,'-r');
% axis([0 1000 -3 5]);
% xlabel('Age (ka)')
% box on




y_plot_El = y * max(SiTi_Elgy)/max(y)-2.5;

figure;
hold on
plot(age_Elgy,SiTi_Elgy,'-k');
plot(x,y_plot_El,'-r','linewidth',3);
axis([0 1000 -2.5 3]);
set(gca,'ytick',[0 0.5 1.0 1.5 2.0 2.5 3.0]);
set(gca,'yticklabels',[0.0 0.5 1.0 1.5 2.0 2.5 3.0]);

xlabel('Age (ka)')
ylabel('Primary productivity (Si/Ti) at Lake Elgygytgyn');
box on

%return
load("Herectus_01Ma.txt");
age_Herectus_Prob = 2000-(1000:1941);
Herectus_Prob = Herectus_01Ma;

% figure;
% plot(age_Herectus_Prob,Herectus_Prob,'-b');

figure;
hold on
plot(LR04_age,plot_LR04_d18O,'-b');
%yyaxis right
plot(age_Elgy,SiTi_Elgy,'-k');
plot(x,y_plot_El,'-r');
axis([0 1000 -3 5]);
xlabel('Age (ka)')
box on

figure;
subplot(2,1,1)
plot(LR04_age,LR04_d18O,'-b');
axis ij
axis([0 1000 2.8 5.2]);
ylabel('Global marine \delta^1^8O  (per mil)');
ax = gca;
ax.YColor = [0, 0, 1];
yyaxis right
plot(age_Herectus_Prob,Herectus_Prob,'-m');
axis([0 1000 0 0.13]);
ylabel('Habitat suitability (H. erectus)');

subplot(2,1,2)
plot(age_Elgy,SiTi_Elgy,'-k');
axis([0 1000 0 2.8]);
ylabel('Biological activity)');
yyaxis right
plot(x,y,'-r');
axis([0 1000 0 6.5e-3]);
ylabel('Time (ka)');
ylabel('Burial age (Probability density)');

% % print(resize,'-bestfit',Diring_Fig4_Prelim,'-dpdf');
% print('-bestfit','-dpdf','Diring_Fig4_Prelim');


figure;

plot(age_Elgy,SiTi_Elgy,'-k');
axis([0 1000 0 2.8]);
ylabel('Si/Ti  (Lake Elgygytgyn)');
yyaxis right
plot(x,y,'-r');
axis([0 1000 0 6.5e-3]);
ylabel('Time (ka)');
ylabel('Burial age (Probability density)');

% print(resize,'-bestfit',Diring_Fig4_Prelim,'-dpdf');
print('-bestfit','-dpdf','Diring_Fig4_Prelim');

