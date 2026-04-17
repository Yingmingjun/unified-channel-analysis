%% PAS plotter %%%%%%%%%%%%%%%%%%%%%%%%%%%
function PASplotter(PAS_angles,PAS_powers,varargin)
    pType=0;
    Thres=-500;

    if(~isempty(varargin))
      for i=1:length(varargin)
        if(string(varargin(i))=="Stem")
            pType=cell2mat(varargin(i+1));
        elseif (string(varargin(i))=="Threshold")
            Thres=cell2mat(varargin(i+1));
        end
      end
    end
    
    switch(pType)
        case 0
            figure;
            theta=PAS_angles*(pi/180);
            p=polarplot(theta([1:end 1]),PAS_powers([1:end 1]),'-o');
            p.MarkerSize=2;
            p.LineWidth=2;
            ax = gca;
            ax.ThetaZeroLocation = 'top';
            ax.ThetaDir='clockwise';
            rlim([min(PAS_powers)-2 max(PAS_powers)+5]);
            hold on;

        case 1
            hold on;
            MPC_Pwrs_base=(min(PAS_powers)-2).*ones(size(MPC_Pwrs));
            MPC_plot_pwrs=[PAS_powers;MPC_Pwrs_base];
            PAS_angles=deg2rad(PAS_angles);
            PAS_angles=[PAS_angles';PAS_angles'];
            p=polarplot(PAS_angles,MPC_plot_pwrs,'r.-');
            p.MarkerSize=2;
            p.LineWidth=2;
    end
    
    if (Thres>-500)
        theta = linspace(0,2*pi,360);
        polarplot(theta,Thres+zeros(size(theta)),'k--');
        polarplot(theta,(Thres-10)+zeros(size(theta)),'k--');
        if((Thres-10)<min(PAS_powers)-2)
            rlim([min([Thres-10,min(PAS_powers)-2]) max(PAS_powers)+5]);
        end
    end
    hold off;
end