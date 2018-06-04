function [dataout]=aE_sort_sAP_aAP(dirs,xlsdata,xlsnum,valtozok)
% sorts axonal from somatic APs with the help of the user
valtozok_def.timeback=.002;
valtozok_def.timeforward=.002;
valtozok_def.depolratewindow=.001;
valtozok_def.baselineVwindow=.005;
valtozok_def.timeborders=[0,inf];
valtozok_def.dvmaxborders=[0,0];
valtozok_def.ratedeofdepol_border=NaN;
valtozok_def.threshold_border=NaN;
if nargin<4
    valtozok=valtozok_def;
else
    valtozonevek=fieldnames(valtozok_def);
    for i=1:length(valtozonevek)
        if ~isfield(valtozok,valtozonevek{i})
            valtozok.(valtozonevek{i})=valtozok_def.(valtozonevek{i});
        end
    end
end
dataout=struct;
%%
if xlsnum>0
    ID=xlsdata(xlsnum).ID;
    load([dirs.eventdir,ID],'eventdata');
    load([dirs.bridgeddir,ID],'bridgeddata','stimdata');
    % stimdata=
    
    figure(1)
    close(1)
    figure(2)
    close(2)
    figure(3)
    close(3)
    figure(4)
    close(4)
    figure(5)
    close(5)
    figure(6)
    close(6)
    figure(33)
    close(33)
    
    APwaves=struct;
    
    
    
    % if ~isempty(eventdata) & ~isempty(fieldnames(eventdata))
    apidxes=find(strcmp({eventdata.type},'AP'));
    prevsweepnum=NaN;
    for eventi=1:length(eventdata)
        eventdata(eventi).maxdv=0;
    end
    for apii=1:length(apidxes)
        api=apidxes(apii);
        sweepnum=eventdata(api).sweepnum;
        if sweepnum~=prevsweepnum
            RS=stimdata(sweepnum).RS/10^6;
            y=bridgeddata(sweepnum).y;
            si=round(bridgeddata(sweepnum).si*10^6)/10^6;
            yfiltered=moving(y,2);
            dyfiltered=diff(yfiltered)/si;
            %                     dyfiltered_longfilt=moving(y,round(.0005/si));
            prevsweepnum=sweepnum;
            stepbackforthresh=round(.0002/si);
            stepback=round(valtozok.timeback/si);
            stepforward=round(valtozok.timeforward/si);
        end
        onseth=eventdata(api).onseth;
        maxh=eventdata(api).maxh;
        threshh=maxh-stepbackforthresh;
        while dyfiltered(threshh)<max(dyfiltered(max(1,threshh-5):threshh)) & threshh>stepback+3
            threshh=threshh-1;
        end
        while ~((dyfiltered(threshh)<50) & mean(dyfiltered(max(1,threshh-round(.0001/si)):threshh))<50)  & threshh>stepback+3 %
            threshh=threshh-1;
        end
        threshv=yfiltered(threshh);
        eventdata(api).threshv=threshv;
        eventdata(api).APamplitude=eventdata(api).maxval-eventdata(api).threshv;
        depolrateV=yfiltered(max(threshh-round(valtozok.depolratewindow/si),1):threshh-round(.0001/si));
        depolratet=(1:length(depolrateV))*si;
        p=polyfit(depolratet',depolrateV,1);
        eventdata(api).depolrate=p(1);
        eventdata(api).baselineV=mean(yfiltered(max(threshh-round(valtozok.baselineVwindow/si),1):threshh));
        
        dv=diff(y(threshh:maxh))/si;
        [maxdval,maxdvh]=max(dv);
        maxdvh=maxdvh+threshh-1;
        centerh=threshh;%maxdvh;
        
        t=[-stepback:stepforward]*si*1000;
        
        
        
        if length(y)-stepforward<centerh
            vegh=length(y);
            nanvegen=stepforward-(length(y)-centerh);
        else
            vegh=centerh+stepforward;
            nanvegen=0;
        end
        if stepback>=centerh
            kezdeth=1;
            nanelejen=stepback-centerh+1;
        else
            kezdeth=centerh-stepback;
            nanelejen=0;
        end
        
        v=[nan(nanelejen,1);y(kezdeth:vegh)';nan(nanvegen,1)]';
        movingn=3;
        %             v=y([-stepback:stepforward]+centerh);
        dv=diff(moving(v,movingn))'/si;
        ddv=diff(moving(dv,movingn))'/si;
        dddv=diff(moving(ddv,movingn))'/si;
        vdv=mean([v(2:end);v(1:end-1)]);
        vddv=mean([vdv(2:end);vdv(1:end-1)]);
        vdddv=mean([vddv(2:end);vddv(1:end-1)]);
        tdv=mean([t(2:end);t(1:end-1)]);
        tddv=mean([tdv(2:end);tdv(1:end-1)]);
        tdddv=mean([tddv(2:end);tddv(1:end-1)]);
        APwaves(apii).t=t';
        APwaves(apii).v=v'*1000;
        APwaves(apii).dv=dv';
        APwaves(apii).ddv=ddv';
        APwaves(apii).dddv=dddv';
        APwaves(apii).tdv=tdv';
        APwaves(apii).tddv=tddv';
        APwaves(apii).tdddv=tdddv';
        APwaves(apii).vdv=vdv'*1000;
        APwaves(apii).vddv=vddv'*1000;
        APwaves(apii).vdddv=vdddv'*1000;
        APwaves(apii).si=si;
        APwaves(apii).RS=RS;
        APwaves(apii).maxtime=eventdata(api).maxtime;
        APwaves(apii).stimulated=eventdata(api).stimulated;
        APwaves(apii).threshv=eventdata(api).threshv;
        APwaves(apii).depolrate=eventdata(api).depolrate;
        APwaves(apii).baselineV=eventdata(api).baselineV;

        APwaves(apii).maxdv=max(dv);
        eventdata(api).maxdv=max(dv);
        
        % elso derivalt helyi minimumanak keresese a masodik derivalton
        difi=maxdvh-threshh;
        ddvsegment=ddv(stepback-difi:stepback);
        vege=length(ddvsegment);
        while vege>1 & (ddvsegment(vege)<ddvsegment(vege-1) | ddvsegment(vege)<0)
            vege=vege-1;
        end
        eleje=1;
        while vege>eleje & (ddvsegment(eleje)<ddvsegment(eleje+1) | ddvsegment(eleje)<0)
            eleje=eleje+1;
        end
        %                 if any(moving(ddvsegment(eleje:vege),2,'max')<0)
        %                     %                 figure(1)
        %                     %                 clf
        %                     %                 plot(ddvsegment,'k-')
        %                     %                 hold on
        %                     %                 plot(ddvsegment(1:vege),'r-')
        %                     %                 pause
        %                     eventdata(api).axonalAP=true;
        %                     eventdata(api).somaticAP=false;
        %                     APwaves(apii).axonalAP=true;
        %                     APwaves(apii).somaticAP=false;
        %                 else
        %                     eventdata(api).axonalAP=false;
        %                     eventdata(api).somaticAP=true;
        %                     APwaves(apii).axonalAP=false;
        %                     APwaves(apii).somaticAP=true;
        %                 end
    end
    
    figure(6)
    clf
    needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) &strcmp({eventdata.type},'AP'));
    plot([eventdata(needed).APamplitude],[eventdata(needed).maxdv],'ko')
    ylabel('maxdV/dt (mv/ms)')
    xlabel('amplitude');
    if diff(valtozok.dvmaxborders)==0
        pause
        [~,mindvperdt]=ginput(2);
        valtozok.dvmaxborders=sort(mindvperdt);
    else
        mindvperdt=valtozok.dvmaxborders;
    end
    figure(3)
    clf
    hold on
    % hist([apdata.threshv],100)
    %             needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.axonalAP] );
    %             plot([eventdata(needed).APamplitude],[eventdata(needed).threshv],'ro')
    needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.maxdv]>min(mindvperdt) &[eventdata.maxdv]<max(mindvperdt));
    plot([eventdata(needed).APamplitude],[eventdata(needed).threshv]*1000,'ko')
    needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.stimulated]==1 & [eventdata.maxdv]>min(mindvperdt) &[eventdata.maxdv]<max(mindvperdt));
    plot([eventdata(needed).APamplitude],[eventdata(needed).threshv]*1000,'bo')
    ylabel('AP threshold (V)')
    xlabel('AP amplitude (mV)')
    
    figure(4)
    clf
    hold on
    % hist([apdata.threshv],100)
    %             needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.axonalAP] );
    %             plot([eventdata(needed).baselineV],[eventdata(needed).threshv],'ro')
    needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2)& [eventdata.maxdv]>min(mindvperdt) &[eventdata.maxdv]<max(mindvperdt));
    plot([eventdata(needed).baselineV]*1000,[eventdata(needed).threshv]*1000,'ko')
    needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.stimulated]==1& [eventdata.maxdv]>min(mindvperdt) &[eventdata.maxdv]<max(mindvperdt));
    plot([eventdata(needed).baselineV]*1000,[eventdata(needed).threshv]*1000,'bo')
    ylabel('AP threshold (mV)')
    xlabel('baseline V0 (mV)')
    
    figure(5)
    clf
    hold on
    % hist([apdata.threshv],100)
    %             needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.axonalAP] );
    %             plot([eventdata(needed).depolrate],[eventdata(needed).threshv],'ro')
    needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.maxdv]>min(mindvperdt) &[eventdata.maxdv]<max(mindvperdt));
    plot([eventdata(needed).depolrate],[eventdata(needed).threshv]*1000,'ko','LineWidth',3,'MarkerFaceColor',[0 0 0])
    
    needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) & [eventdata.stimulated]==1& [eventdata.maxdv]>min(mindvperdt) &[eventdata.maxdv]<max(mindvperdt));
    plot([eventdata(needed).depolrate],[eventdata(needed).threshv]*1000,'bo','LineWidth',3,'MarkerFaceColor',[0 0 1])
    ylabel('AP threshold (mV)')
    xlabel('rate of depolarization (mV/ms)')
    if isnan(valtozok.ratedeofdepol_border) | isnan(valtozok.threshold_border)
        pause
        [x,y]=ginput(1);
    end
    if ~isnan(valtozok.ratedeofdepol_border)
        x=valtozok.ratedeofdepol_border;
    end
    if ~isnan(valtozok.threshold_border)
        y=valtozok.threshold_border;
    end
end
needed=find([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2) &[eventdata.maxdv]>min(mindvperdt) &[eventdata.maxdv]<max(mindvperdt));
    plot([x,x],[min([eventdata(needed).threshv]),max([eventdata(needed).threshv])]*1000,'k-','LineWidth',2)
    plot([min([eventdata(needed).depolrate]),max([eventdata(needed).depolrate])],[y,y],'k-','LineWidth',2)
    for api=1:length(eventdata)
        if any(api==apidxes);
            apii=find(api==apidxes);
            if [eventdata(api).maxdv]<min(mindvperdt) | [eventdata(api).maxdv]>max(mindvperdt)
                eventdata(api).axonalAP=false;
                eventdata(api).somaticAP=false;
                APwaves(apii).axonalAP=false;
                APwaves(apii).somaticAP=false;
                eventdata(api).type='ep';
            elseif eventdata(api).depolrate<=x | eventdata(api).threshv<=y/1000
                eventdata(api).axonalAP=true;
                eventdata(api).somaticAP=false;
                APwaves(apii).axonalAP=true;
                APwaves(apii).somaticAP=false;
            else
                eventdata(api).axonalAP=false;
                eventdata(api).somaticAP=true;
                APwaves(apii).axonalAP=false;
                APwaves(apii).somaticAP=true;
            end
        else
            eventdata(api).axonalAP=false;
            eventdata(api).somaticAP=false;
        end
    end
    
    for ii=1:2
        figure(ii)
        clf
        sis=unique([APwaves.si]);
        for i=1:length(sis)
            if ii==1
                needed=find([APwaves.si]==sis(i) & [APwaves.axonalAP]==true & [APwaves.maxtime]>=valtozok.timeborders(1) &[APwaves.maxtime]<=valtozok.timeborders(2) &[APwaves.stimulated]==false);
            else
                needed=find([APwaves.si]==sis(i) & [APwaves.somaticAP]==true & [APwaves.maxtime]>=valtozok.timeborders(1) &[APwaves.maxtime]<=valtozok.timeborders(2) &[APwaves.stimulated]==false);
            end
            subplot(2,2,1)
            hold on
            plot([APwaves(needed).t],[APwaves(needed).v]);
            axis tight
            ylabel('Voltage (mV)')
            xlabel('Time (ms)')
            subplot(2,2,2)
            hold on
            plot([APwaves(needed).tdv],[APwaves(needed).dv]);
            axis tight
            ylabel('dV/dt (mV/ms)')
            xlabel('Time (ms)')
            subplot(2,2,3)
            hist([APwaves(needed).RS]);
            xlabel('RS (MOhm)')
            ylabel('count')
            subplot(2,2,4)
            hold on
            plot([APwaves(needed).vdv],[APwaves(needed).dv]);
            axis tight
            ylabel('dV/dt (mV/ms)')
            xlabel('Voltage (mV)')
        end
    end
    
    
    
    
    figure(33)
    clf
    hist([APwaves.RS]);
    xlabel('RS (MOhm)')
    axonalapnum=length(find([APwaves.axonalAP]==true&[APwaves.stimulated]==false& [APwaves.maxtime]>=valtozok.timeborders(1) &[APwaves.maxtime]<=valtozok.timeborders(2)  ));
    somaticaptnum=length(find([APwaves.somaticAP]==true & [APwaves.stimulated]==false& [APwaves.maxtime]>=valtozok.timeborders(1) &[APwaves.maxtime]<=valtozok.timeborders(2) ));
    stimulatedapnum=length(find([APwaves.somaticAP]==true&[APwaves.stimulated]==true& [APwaves.maxtime]>=valtozok.timeborders(1) &[APwaves.maxtime]<=valtozok.timeborders(2) ));
    disp([num2str(axonalapnum),' axonal APs and ',num2str(somaticaptnum),' somatic APs found - ' ,num2str(stimulatedapnum),'AP by somatic current injection during the inspected ',num2str(diff(valtozok.timeborders)),' seconds'])
    
    
    figure(5)
    saveas(gcf,[dirs.figuresdir,ID,'_threshold_rateofdepol'],'pdf')
    saveas(gcf,[dirs.figuresdir,ID,'_threshold_rateofdepol'],'jpg')
    figure(1)
    saveas(gcf,[dirs.figuresdir,ID,'_axonal_spikes'],'pdf')
    saveas(gcf,[dirs.figuresdir,ID,'_axonal_spikes'],'jpg')
    figure(2)
    saveas(gcf,[dirs.figuresdir,ID,'_somatic_spikes'],'pdf')
    saveas(gcf,[dirs.figuresdir,ID,'_somatic_spikes'],'jpg')
    dataout.APwaves=APwaves([APwaves.maxtime]>=valtozok.timeborders(1) &[APwaves.maxtime]<=valtozok.timeborders(2));
    dataout.eventdata=eventdata([eventdata.maxtime]>=valtozok.timeborders(1) &[eventdata.maxtime]<=valtozok.timeborders(2));
    dataout.bridgeddata=bridgeddata;
    dataout.stimdata=stimdata;
end

