% Angular Spread using Fleury's definition
% ang should be on radians
% aps power vs angle
% as is a value from 0 to 1
% This is delta summation, do not include 2pi point

function as=ASfleury(ang,aps)
    % Power=trapz(ang,aps);% Compute total power using trapz integral
    % mean_power=trapz(ang,exp(1j.*ang).*aps)/Power; % We compute the mean power using Fleury's def
    % as=sqrt(trapz(ang,abs(exp(1j.*ang)-mean_power).^2.*aps)/Power);  % We compute the as using Fleury's def
    Power=sum(aps);% Compute total power 
    mean_power=sum(exp(1j.*ang).*aps)/Power; % We compute the mean power using Fleury's def
    as=sqrt(sum((abs(exp(1j.*ang)-mean_power).^2).*aps)/Power);  % We compute the as using Fleury's def
end

% Example to test code from Prof. Molisch book Chapter 6
% ang=(0:359)*pi/180;
% aps=[ones(1,91),0*ones(1,250),ones(1,19)];
% as=ASfleury(ang,aps)*180/pi;
%     figure
%     plot(ang*180/pi,aps),grid minor,xlabel('Angle[^o]'),ylabel('APS')