%function PPINI_analysis

clear all; close all;

site = ' ';
name = 'mc_sink_Diring_Modified';    % Library name 
file = ['Diring_Input_High.xlsx'];      % Excel sheet with sample information
%file = ['Diring_Input_Only1175.xlsx'];      % Excel sheet with sample information
%file = ['Diring_Input_Only832_1480.xlsx'];      % Excel sheet with sample information
%file = ['Diring_Input_Only832.xlsx'];

%%% Loading the field data from excel document containing the following:
%%% sample-ID, Be conc. [at/g], Be error [at/g], Al conc. [at/g], Al error [at/g], estimated sampling depths [cm]

cd other/samples
T = readtable(file);
names = table2array(T(:,1));
NBe = table2array(T(:,2));

NBe_unc = table2array(T(:,3));  
NAl = table2array(T(:,4));
NAl_unc = table2array(T(:,5));
depths = table2array(T(:,6));
cd ../code

% figure(10);
% hold on
% plot(NBe./1000,NAl./NBe,'.r','Markersize',25);
% box on 
% axis([0 400 3 7]);
% xlabel('^{10}Be concentrations (10^{3} at/g)');
% ylabel('^{26}Al/^{10}Be ratio');



f_m = 0;%0.01;   % Added muon production uncertainty fraction

%%% Advanced section for quickly omitting samples
k = 1:numel(NBe);
% k([1 2 3 4 5 10]) = [];
% k([6 7 8 9 10 11]) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%          Code form here           %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; rng(1); tic

%%% Loading Library as an example to get age and erosion rate information 
m = matfile(name);

%%% All the possible burial ages
ut = unique(m.Ages_fin);
ue = unique(m.rate);
A = zeros(numel(ue),numel(ut),numel(k)); 
A_prod = ones(numel(ue),numel(ut));
clr_hsv = hsv(64);
clr_hsv = clr_hsv(10:end,:);
n_sub = ceil(sqrt(numel(k)));
load imola
ColorMap = imola; ColorMap(1,:) = 1;
hist_info = {};

figure(2) %% This is just for plotting.
leg2(1) = plot(m.NBe_tot(1,1:1000:end),m.NAl_tot(1,1:1000:end),'.k');
hold on
leg2(2) = plot(-100,-100,'.','Color',[1 0.6 0.1]);
ax = gca;
leg2(3) = plot(ax.XLim,ax.XLim*6.95,'-k');
leg_str = {'1 in 1000 of simulations';'Accepted simulations';'Ratio = -'};

if numel(k) > 3
    for i=4:numel(k)
        leg2(i) = plot([-100 -100],[-100 -100],'-','Color',[1 1 1]);
        leg_str{i} = ' ';
    end
end

for i=k
    leg_str(end+1) = names(i);
end

w_Be = NBe_unc;
w_Al = NAl_unc;

rep_max = 10;
old_age = 1;
old_e = 1;
old_NBe_post = 1;
old_NAl_post = 1;

mean_ages = zeros(1,rep_max);
sigma_ages = zeros(1,rep_max);
mean_es = zeros(1,rep_max);
sigma_es = zeros(1,rep_max);
            
for rep = 1:rep_max
    rng(1)
    for j = 1:numel(k)
        i = k(j); % Like 'j' but start from 1

        %%% Loading the 'libraries'
            str = name;
            m = matfile(str);
            NBe_post = m.NBe_post;
            NAl_post = m.NAl_post;
            NBe_tot = m.NBe_tot;
            NAl_tot = m.NAl_tot;
            erate_fin = m.rate;
            Ages_fin = m.Ages_fin;

            %%% Remove concentrations with too high post-burial production compared to the samples.
            [max_conc,Be_idx] = min(NBe(k));
            max_post_Be = NBe(k(Be_idx)) + 2*(w_Be(k(Be_idx))+NBe_unc(k(Be_idx))); % maximum post burial production we can allow
            [max_conc,Al_idx] = min(NAl(k));
            max_post_Al = NAl(k(Al_idx)) + 2*(w_Al(k(Al_idx))+NAl_unc(k(Al_idx)));

            to_keep = find(NBe_post < max_post_Be & NAl_post < max_post_Al);

            NBe_post = NBe_post(to_keep);
            NAl_post = NAl_post(to_keep);
            NBe_tot = NBe_tot(to_keep);
            NAl_tot = NAl_tot(to_keep);
            erate_fin = erate_fin(to_keep);
            Ages_fin = Ages_fin(to_keep);

            L_NBe{j} = zeros(size(NBe_tot));
            L_NAl{j} = zeros(size(NBe_tot));
            L{j} = zeros(size(NBe_tot));

        % Calculates the likelihood at each simulated data point
        NBe_dd= NBe_tot - NBe(i);
        L_NBe{j} = ((2*pi)^2*abs((w_Be(i)+NBe_unc(i))))^-.5.*exp(-.5*NBe_dd.^2./((w_Be(i)+NBe_unc(i))).^2);

        NAl_dd= NAl_tot - NAl(i);
        L_NAl{j} = ((2*pi)^2*abs((w_Al(i)+NAl_unc(i))))^-.5.*exp(-.5*NAl_dd.^2./((w_Al(i)+NAl_unc(i))).^2);

        L{j} = L_NBe{j}.*L_NAl{j};

        maxL = max(L{j});

        % Pick points through rejection sampling
        Pac = L{j}/maxL;
        r = rand(size(L{j}));
        filter = find(r < Pac);

        Ages = Ages_fin(filter);  
        erates = erate_fin(filter);

        for c1 = 1:numel(ue)
            for c2 = 1:numel(ut)
                check = find(erates == ue(c1) & Ages == ut(c2));
                A(c1,c2,j) = numel(check);
            end
        end

        A_prod = A_prod.*(A(:,:,j)/sum(A(:,:,j),'all'));

        figure(3)
        subplot(n_sub,n_sub,j)
            imagesc(ut*1e-6,ue,A(:,:,j));     
            colormap(gca,ColorMap)
            xlabel('[Ma]')
            ylabel('[g/cm2/yr]')
    end
    
    A_prod = A_prod./sum(A_prod,'all');
    
    try
        f_t = fit(ut'/1e6,sum(A_prod,1)'./sum((A_prod),'all')','gauss1');
        b = f_t.b1;
        c = f_t.c1;
        mean_ages(rep) = b*1e6;
        sigma_ages(rep) = c*1e6/sqrt(2);
        disp(['Mean age:         ',num2str(round(mean_ages(rep)*1e-3)),' ka                  (',num2str(rep),')'])
        disp(['Estimated 1std:   ',num2str(round(sigma_ages(rep)*1e-3)),' ka'])

        f_e = fit(ue'*1e6,sum(A_prod,2)./sum((A_prod),'all'),'gauss1');
        b_e = f_e.b1;
        c_e = f_e.c1;
        mean_es(rep) = round(b_e,2); 
        sigma_es(rep) = round(c_e/sqrt(2),2);
        disp(['Mean rate:       ',num2str(mean_es(rep)),' g/cm2/Myr'])
        disp(['Estimated 1std:   ',num2str(sigma_es(rep)),' g/cm2/Myr'])
        disp('---------------------------------------------------')
        
    catch
        error('No overlapping ages. Try to refine source/sink parameters')
    end

    [~,idx_age] = min(abs(mean_ages(rep) - Ages_fin));
    age_close = Ages_fin(idx_age);
    [~,idx_e] = min(abs(mean_es(rep)*1e-6 - erate_fin));
    e_close = erate_fin(idx_e);
    idx_ens = find(age_close == Ages_fin & e_close == erate_fin);
    w_Be = f_m*ones(size(NBe))*NBe_post(idx_ens(1));
    w_Al = f_m*ones(size(NAl))*NAl_post(idx_ens(1));
    
    % Resetting matrices for next run
    A = zeros(numel(ue),numel(ut),numel(k)); 
    A_prod = ones(numel(ue),numel(ut));
    
    thres_age = abs(mean_ages(rep)-old_age)/old_age;
    thres_e = abs(mean_es(rep)-old_e)/old_e;
    thres_NBe = abs(NBe_post(idx_ens(1))-old_NBe_post)/old_NBe_post;
    thres_NAl = abs(NAl_post(idx_ens(1))-old_NAl_post)/old_NAl_post;

    if  thres_NBe < 0.02 && thres_NAl < 0.02
        disp('Threshold criteria reached!')
        break
    end
    
    if  thres_age < 0.02 && thres_e < 0.02
        disp('Threshold criteria reached!')
        break
    end
    
    old_age = mean_ages(rep);
    old_e = mean_es(rep);
    old_NBe_post = NBe_post(idx_ens(1));
    old_NAl_post = NAl_post(idx_ens(1));
    
end 

close Figure 3

for j = 1:numel(k)
    i = k(j); % Like 'i' but start from 1
    
        %%% Loading the 'libraries'
            str = name;
            m = matfile(str);
            NBe_post = m.NBe_post;
            NAl_post = m.NAl_post;
            NBe_tot = m.NBe_tot;
            NAl_tot = m.NAl_tot;
            erate_fin = m.rate;
            Ages_fin = m.Ages_fin;
            erate_source = m.erate_source;
            NBe_inh = m.NBe_inh_initial;
            NAl_inh = m.NAl_inh_initial;
            t_expo = m.t_expo;
            t_expo2 = m.t_expo2;
            t_bur = m.t_bur;

            %%% Remove concentrations with too high post-burial production compared to
            %%% the samples.
            [max_conc,Be_idx] = min(NBe(k));
            max_post_Be = NBe(k(Be_idx)) + 2*(w_Be(k(Be_idx))+NBe_unc(k(Be_idx))); % maximum post burial production we can allow
            [max_conc,Al_idx] = min(NAl(k));
            max_post_Al = NAl(k(Al_idx)) + 2*(w_Al(k(Al_idx))+NAl_unc(k(Al_idx)));

            to_keep = find(NBe_post < max_post_Be & NAl_post < max_post_Al);

            NBe_post = NBe_post(to_keep);
            NAl_post = NAl_post(to_keep);
            NBe_tot = NBe_tot(to_keep);
            NAl_tot = NAl_tot(to_keep);
            erate_fin = erate_fin(to_keep);
            Ages_fin = Ages_fin(to_keep);
            erate_source = erate_source(to_keep);
            NBe_inh = NBe_inh(to_keep);
            NAl_inh = NAl_inh(to_keep);
            t_expo = t_expo(to_keep);
            t_expo2 = t_expo2(to_keep)';
            t_bur = t_bur(to_keep);

            L_NBe{j} = zeros(size(NBe_tot));
            L_NAl{j} = zeros(size(NBe_tot));
            L{j} = zeros(size(NBe_tot));

        % Calculates the likelihood at each simulated data point
        NBe_dd= NBe_tot - NBe(i);
        L_NBe{j} = ((2*pi)^2*abs((w_Be(i)+NBe_unc(i))))^-.5.*exp(-.5*NBe_dd.^2./((w_Be(i)+NBe_unc(i))).^2);

        NAl_dd= NAl_tot - NAl(i);
        L_NAl{j} = ((2*pi)^2*abs((w_Al(i)+NAl_unc(i))))^-.5.*exp(-.5*NAl_dd.^2./((w_Al(i)+NAl_unc(i))).^2);

        L{j} = L_NBe{j}.*L_NAl{j};

        maxL = max(L{j});

        % Pick points through rejection sampling
        Pac = L{j}/maxL;
        r = rand(size(L{j}));
        filter = find(r < Pac);

        Ages = Ages_fin(filter);  
        erates = erate_fin(filter);

        for c1 = 1:numel(ue)
            for c2 = 1:numel(ut)
                check = find(erates == ue(c1) & Ages == ut(c2));
                A(c1,c2,j) = numel(check);
            end
        end

        A_prod = A_prod.*(A(:,:,j)/sum(A(:,:,j),'all'));
        
    figure(3)
    hold on   
    subplot(n_sub,n_sub,j)
    imagesc(ut*1e-6,ue*1e6,A(:,:,j));
    colormap(gca,ColorMap)
    title(names(i))
    ax = gca;
    xlabel('[Ma]')
    ylabel('[g/cm2/Myr]')
    ax.TickLength = [0.01 0.01];
%     propert = findall(gcf,'-property','FontSize');
%     set(propert,'FontSize',15)
    
    hist_info{j} = [Ages_fin(filter);erate_fin(filter)*1e6;erate_source(filter)*1e6;NBe_inh(filter);NAl_inh(filter);t_expo(filter);t_expo2(filter);t_bur(filter)];

    figure(2)
    hold on
    plot(NBe_tot(filter),NAl_tot(filter),'.','Color',[1 0.6 0.1])

end

A_prod = A_prod./sum(A_prod,'all');

figure(1);
    colormap(ColorMap)
    subplot(3,3,[2,3,5,6])
    imagesc(ut*1e-6,ue*1e6,A_prod)
%     text(0.90,0.95,'b)','Units','normalized','Color',[0 0 0],'FontSize',10)
    title(site)
    box on
    set(gca,'XTick',[], 'YTick', [])
    
    subplot(3,3,[8,9])
    try
        f_t = fit(ut'/1e6,(sum(A_prod,1)./sum(A_prod,'all'))','gauss1');
        b = f_t.b1;
        c = f_t.c1;
        mean_age = b*1e6;
        sigma_age = c*1e6/sqrt(2);
        disp(['Mean age:         ',num2str(round(mean_age*1e-3)),' ka'])
        disp(['Estimated 1std:   ',num2str(round(sigma_age*1e-3)),' ka'])
        hold on
        xlabel('Sink burial age [Ma]','FontSize',10)
        xlim([min(ut),max(ut)]*1e-6)
        plot(ut*1e-6,sum(A_prod,1)./sum(A_prod,'all'),'-k','LineWidth',2)
        t = linspace(min(ut),max(ut),1001)/1e6;
        if mean_age < 0
            cum_A = cumsum(sum(A_prod,1));
            idx_1 = find(cum_A > 0.50);
            disp(['50% qunatile: ',num2str(ut(idx_1(1))), 'yr'])
            idx_2 = find(cum_A > 0.75);
            disp(['75% qunatile: ',num2str(ut(idx_2(1))), 'yr'])
            idx_3 = find(cum_A > 0.90);
            disp(['90% qunatile: ',num2str(ut(idx_3(1))), 'yr'])
            idx_4 = find(cum_A > 0.95);
            disp(['95% qunatile: ',num2str(ut(idx_4(1))), 'yr'])
            %     arrow = annotation('textarrow',[0.62 0.52],[0.24 0.24], 'horizontalAlignment', 'left','String',...
%         [{['50% quantile:  ',num2str(round(ut(idx_1(1))*1e-3)),' ka']},...
%         {['75% quantile:  ',num2str(round(ut(idx_2(1))*1e-3)),' ka']},...
%         {['90% quantile:  ',num2str(round(ut(idx_3(1))*1e-3)),' ka']},...
%         {['95% quantile:  ',num2str(round(ut(idx_4(1))*1e-3)),' ka']}]);
        else
            plot(t,f_t(t),'-r')
            
          
            
        end
%         annotation('textarrow',[0.58 0.64],[0.27 0.26],'String','11.4 \pm 2.9 Ma')
%         annotation('textarrow',[0.72 0.68],[0.27 0.26],'String','4.5 \pm 0.7 Ma')

        box on
%         ax = gca;
%         ax.TickLength = [0.01 0.01];
        set(gca,'TickLength', [0.01 0.01])
        propert = findall(gcf,'-property','FontSize');
        set(propert,'FontSize',15)
  


    subplot(3,3,[1,4])
        f_e = fit(1e6*ue',(sum(A_prod,2)./sum(A_prod,'all')),'gauss1');
        b_e = f_e.b1;
        c_e = f_e.c1;
        mean_e = round(b_e,2);
        sigma_e = round(c_e/sqrt(2),2);
        disp(['Mean rate:         ',num2str(mean_e),' g/cm2/Myr'])
        disp(['Estimated 1std:   ',num2str(sigma_e),' g/cm2/Myr'])
        hold on
        if m.ero == 1
            ylabel('Erosion rate [g/cm2/Myr]','FontSize',10)
        elseif m.ero == 0
            ylabel('Accumulation rate [g/cm2/Myr]','FontSize',10)
        end
        ylim(1e6*[min(ue),max(ue)])
        plot(sum(A_prod')./sum(sum(A_prod)),1e6*ue,'-k','LineWidth',2)
        set(gca,'Ydir','reverse')
        set(gca,'FontSize',11)
        e = linspace(min(ue),max(ue),1001)*1e6;
        ax = gca;
        ax.XLim(1) = 0.00;
        box on
        ax.TickLength = [0.01 0.01];
        propert = findall(gcf,'-property','FontSize');
        set(propert,'FontSize',15)
        if mean_e < 0
            cum_A = cumsum(sum(A_prod,2));
            idx_1 = find(cum_A > 0.68);
            f1 = ue(idx_1(1))*(cum_A(idx_1(1)) - 0.68)/(cum_A(idx_1(1)) - cum_A(idx_1(1)-1));
            f2 = ue(idx_1(1)-1)*(0.68 - cum_A(idx_1(1)-1))/(cum_A(idx_1(1)) - cum_A(idx_1(1)-1));
            disp(['68% qunatile: ',num2str(1e6*(f1+f2)), 'g/cm2/Myr'])
            c68 = (f1+f2);
            
            idx_2 = find(cum_A > 0.75);
            f1 = ue(idx_2(1))*(cum_A(idx_2(1)) - 0.75)/(cum_A(idx_2(1)) - cum_A(idx_2(1)-1));
            f2 = ue(idx_2(1)-1)*(0.75 - cum_A(idx_2(1)-1))/(cum_A(idx_2(1)) - cum_A(idx_2(1)-1));
            disp(['75% qunatile: ',num2str(1e6*(f1+f2)), 'g/cm2/Myr'])
            
            idx_3 = find(cum_A > 0.90);
            f1 = ue(idx_3(1))*(cum_A(idx_3(1)) - 0.9)/(cum_A(idx_3(1)) - cum_A(idx_3(1)-1));
            f2 = ue(idx_3(1)-1)*(0.9 - cum_A(idx_3(1)-1))/(cum_A(idx_3(1)) - cum_A(idx_3(1)-1));
            disp(['90% qunatile: ',num2str(1e6*(f1+f2)), 'g/cm2/Myr'])
            
            idx_4 = find(cum_A > 0.95);
            f1 = ue(idx_4(1))*(cum_A(idx_4(1)) - 0.95)/(cum_A(idx_4(1)) - cum_A(idx_4(1)-1));
            f2 = ue(idx_4(1)-1)*(0.95 - cum_A(idx_4(1)-1))/(cum_A(idx_4(1)) - cum_A(idx_4(1)-1));
            disp(['95% qunatile: ',num2str(1e6*(f1+f2)), 'g/cm2/Myr'])
        end
%     plot(f(e),e,'-r')

[~,idx_age] = min(abs(mean_ages(rep) - Ages_fin));
    age_close = Ages_fin(idx_age);
    [~,idx_e] = min(abs(mean_es(rep)*1e-6 - erate_fin));
    e_close = erate_fin(idx_e);
    idx_ens = find(age_close == Ages_fin & e_close == erate_fin);
    Be_postburial = NBe_post(idx_ens(1));
    Al_postburial = NAl_post(idx_ens(1));
    disp(' ')
    disp('Calculated from best estimates:')
    disp(['  ',num2str(round(Be_postburial)),' 10Be at/g produced post burial'])
    disp(['  ',num2str(round(Al_postburial)),' 26Al at/g produced post burial'])
    disp(' ')

    subplot(3,3,7)
    text(0,0.5,{
        ['Estimated age: ',num2str(round(mean_age))],...
        ['Estimated 1std: ',num2str(round(sigma_age))],...
        ['Estimated rate: ',num2str(round(mean_e))],...
        ['Erosion 1std: ',num2str(round(sigma_e))],...
        ' ',...
        },'bold')
    axis off

    catch
        error('No overlapping ages. Try to refine source/sink parameters')
    end


T = table(round((w_Be(k)+NBe_unc(k))./NBe(k)*100,2),round((w_Al(k)+NAl_unc(k))./NAl(k)*100,2),round(NBe_unc(k)./NBe(k)*100,2),round(NAl_unc(k)./NAl(k)*100,2),...
    'VariableNames',{'Applied Be unc (%)','Applied Al unc (%)','Measured Be unc (%)','Measured Al unc (%)'},'RowNames',names(k));
disp(T)


for j = 1:numel(k)
    i = k(j);
    clr = clr_hsv(ceil(j*54/(max(k)+1-min(k))),:); % color to plot with
    Ages = hist_info{j}(1,:);
    erates = hist_info{j}(2,:);
    if mean_e > 0
        accept = find(Ages > mean_age - sigma_age*2 & Ages < mean_age + sigma_age*2 & erates > mean_e - sigma_e*2 & erates < mean_e + sigma_e*2);
    else
        accept = find(Ages > mean_age - sigma_age*2 & Ages < mean_age + sigma_age*2 & erates < c68*2);
    end
    figure(4)
        hold on   
        subplot(n_sub,n_sub,j)
        erate_sources = hist_info{j}(3,:);
        erate_sources = erate_sources(accept);
        [~,edges] = histcounts(log(m.erate_source*1e6),31);
        edges = exp(edges);
        hi = histogram(erate_sources,edges,'FaceColor',clr);
        set(gca,'xscale','log')
        xlabel('Source erosion [m/Myr]')
        title(names(i))        
        text(0.05,0.9,[num2str(round(median(erate_sources))),' m/Myr'],'Units','normalized')
        ax = hi.Parent;
        set(ax,'XTick',[10,100,1000])
BW3 = 0.1;
figure(5)
        hold on   
        subplot(n_sub,n_sub,j)
        NBe_inh = hist_info{j}(4,:);
        NAl_inh = hist_info{j}(5,:);
        NBe_inh = NBe_inh(accept);
        NAl_inh = NAl_inh(accept);
        [~,edges] = histcounts(NAl_inh./NBe_inh,'BinWidth',BW3);
        hi = histogram(NAl_inh./NBe_inh,edges,'FaceColor',clr);
        xlabel('Preburial 26/10 Ratio')
        title(names(i))        
        text(0.05,0.9,['Rm = ',num2str(round(median(NAl_inh./NBe_inh),2))],'Units','normalized')
        axis([3 7 0 1.2*max(histcounts(NAl_inh./NBe_inh,31,'BinWidth',BW3))])
    %         ax = hi.Parent;
%         set(ax,'XTick',[10,100,1000])
    
x_counts = 16;
BW = 3;
        figure(6)
        hold on   
        subplot(n_sub,n_sub,j)
        t_expo_filter = hist_info{j}(6,:);
        t_expo_filter = t_expo_filter(accept)./1000;

        [~,edges] = histcounts(t_expo_filter,'BinWidth',BW);
        hi = histogram(t_expo_filter,edges,'FaceColor',clr);
        xlabel('Preburial exposure time (ka)')
        title(names(i))        
        text(0.05,0.9,['T_{m} (ka) = ',num2str(round(median(t_expo_filter),2))],'Units','normalized')
        axis([0 50 0 1.2*max(histcounts(t_expo_filter,'BinWidth',BW))])


x_counts2 = 16;
BW2 = 0.1;
    figure(7)
        hold on   
        subplot(n_sub,n_sub,j)
        t_bur_filter = hist_info{j}(8,:);
        t_bur_filter = t_bur_filter(accept)./1e6;

        [~,edges] = histcounts(t_bur_filter,'BinWidth',BW2);
        hi = histogram(t_bur_filter,edges,'FaceColor',clr);
        xlabel('Preburial reworking time (Ma)')
        title(names(i))        
        %text(0.05,0.9,['Reworking (Ma) = ',num2str(round(median(t_bur_filter./1e6),2))],'Units','normalized')
        axis([0 3 0 1.2*max(histcounts(t_bur_filter,'BinWidth',BW2))]) 




        


mean_NAl_inh(j) = mean(NAl_inh);
unc_NAl_inh(j) = std(NAl_inh);

    figure(2)
        hold on
        leg1(i) = plot(NBe(i),NAl(i),'*','Color',clr);
end

figure(1)
set(gcf,'Units','normalized','position',[0.1300 0.0575 0.5575 0.8475]);

figure(2)
pb = plot(Be_postburial,Al_postburial,'.r','MarkerSize',20);
%set(gcf,'Units','normalized','position',[0.1300 0.1100 0.7750 0.8150]);
ax = gca;
set(gcf,'Units','normalized','position',[0.1300 0.1100 0.7750 0.8150]);
ax = gca;
legend([leg2,leg1(k)],leg_str','location','northwest','NumColumns',2)
legend([leg2,leg1(k),pb],[leg_str','Post burial'],'location','northwest','NumColumns',2)
legend('boxoff')
ax.TickLength = [0.01 0.01];
propert = findall(gcf,'-property','FontSize');
set(propert,'FontSize',15)
% ax.XLim = [0; 4e4];c
% ax.YLim = [0; 4e4*7];
xlabel('^1^0Be [at/g]')
ylabel('^2^6Al [at/g]')
uistack(leg2(3),'top')

figure(3)
set(gcf,'Units','normalized','position',[0.5703 0.1253 0.3347 0.3257]);


figure(4)
set(gcf,'Units','normalized','position',[0.5703 0.1253 0.3347 0.3257]);
% propert = findall(gcf,'-property','FontSize');
% set(propert,'FontSize',15)

figure(10)
        hold on   
        t_expo2_filter = hist_info{j}(7,:);
        t_expo2_filter = t_expo2_filter(accept);
        hist(t_expo2_filter,20)
        box on
         xlabel('LGM exposure time (ka)')



cd ../..
figure(1)
toc
print(gcf,'name','-dpng','-r350')


%end

return

rho = 2;
L_spal = 160;
L_nmc = 1500;
L_fm = 4320;

TBe = 1.387e6;                                          % 10Be half-life [yr]
TAl = 0.708e6;                                          % 26Al half-life [yr]
lambda_Be = log(2)/TBe;                                 % 10Be mean lifetime [yr^-1]
lambda_Al = log(2)/TAl; 

R = 6.95;
Pspal_Be = 5.02; %atoms/(g*yr)
Pnmc_Be = Pspal_Be*0.015;
Pfm_Be = Pspal_Be*0.005;
P_Be = Pspal_Be + Pnmc_Be + Pfm_Be;

Pspal_Al = Pspal_Be * R; %atoms/(g*yr)
Pnmc_Al = Pspal_Al*0.018;
Pfm_Al = Pspal_Al*0.006;
P_Al = Pspal_Al + Pnmc_Al + Pfm_Al;

Nsim = 1e5;
erate_norand = 1e-5*logspace(-2,1,Nsim);
time_norand = 1e3*logspace(0,3,Nsim);

erate = erate_norand(randperm(Nsim));
time = time_norand(randperm(Nsim));

for i = 1:Nsim;
% NBe_inh_model(i) = mean(NBe_inh) + std(NBe_inh) * randn;
% NAl_inh_model(i) = mean(NAl_inh) + std(NAl_inh) * randn;

fac_Be_spal(i) = (lambda_Be+(erate(i)*rho)/L_spal);
fac_Be_nmc(i) = (lambda_Be+(erate(i)*rho)/L_nmc);
fac_Be_fm(i) = (lambda_Be+(erate(i)*rho)/L_fm);

fac_Al_spal(i) = (lambda_Al+(erate(i)*rho)/L_spal);
fac_Al_nmc(i) = (lambda_Al+(erate(i)*rho)/L_nmc);
fac_Al_fm(i) = (lambda_Al+(erate(i)*rho)/L_fm);

NBe_inh_model(i) = Pspal_Be/fac_Be_spal(i)*(1-exp(-fac_Be_spal(i)*time(i)));% + Pnmc_Be/fac_Be_nmc(i)*(1-exp(-fac_Be_nmc(i)*time(i))) + Pfm_Be/fac_Be_fm(i)*(1-exp(-fac_Be_fm(i)*time(i)));
NAl_inh_model(i) = Pspal_Al/fac_Al_spal(i)*(1-exp(-fac_Al_spal(i)*time(i)));% + Pnmc_Al/fac_Al_nmc(i)*(1-exp(-fac_Al_nmc(i)*time(i))) + Pfm_Al/fac_Al_fm(i)*(1-exp(-fac_Al_fm(i)*time(i)));
    
end;

 % Calculates the likelihood at each simulated data point
%         NBe_dd= NBe_Hol_fin - NBe_sample;
%         L_NBe = ((2*pi)^2*abs(NBe_sample_unc))^-.5.*exp(-.5*NBe_dd.^2./(NBe_sample_unc).^2);

NBe_inh_mean = mean_NBe_inh(1);
NBe_inh_unc = unc_NBe_inh(1);

NAl_inh_mean = mean_NAl_inh(1);
NAl_inh_unc = unc_NAl_inh(1);

        NBe_dd= NBe_inh_model - NBe_inh_mean;
        NAl_dd= NAl_inh_model - NAl_inh_mean;
        L_NBe = ((2*pi)^2*abs(NBe_inh_unc))^-.5.*exp(-.5*NBe_dd.^2./(NBe_inh_unc).^2);
        L_NAl = ((2*pi)^2*abs(NAl_inh_unc))^-.5.*exp(-.5*NAl_dd.^2./(NAl_inh_unc).^2);

        
        
        L = L_NBe.*L_NAl;
        
        maxL = max(L);

        Pac = L/maxL;
        r = rand(size(L));
        filter = find(r < Pac);

 time_accept = time(filter);
 erate_accept = erate(filter)*1e4;

 NBe_inh_model_accept = NBe_inh_model(filter);
 NAl_inh_model_accept = NAl_inh_model(filter);

 figure;
 subplot(1,2,1)
 hist(time_accept,50);
 subplot(1,2,2)
 hist(erate_accept,50);

 figure;
 hold on
 plot(erate*1e4,time,'.r');
 plot(erate_accept,time_accept,'.k');

  figure;
 subplot(1,2,1)
 hold on
 plot(time,NBe_inh_model,'.r');
 plot(time_accept,NBe_inh_model_accept,'.k');
  subplot(1,2,2)
  hold on
 plot(erate*1e4,NBe_inh_model,'.r');
 plot(erate_accept,NBe_inh_model_accept,'.k');



