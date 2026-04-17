function rrc_win = rrc_window(alpha,Nf,BW)

f =linspace(-BW/2,BW/2,Nf);
rrc_win=zeros(1,Nf);
T=2/BW;
for ii=1:Nf
     if abs(f(ii)) < (1-alpha)/(2*T)
         rrc_win(ii) = 1*exp(-1j*pi*f(ii)*T);
     elseif abs(f(ii)) > (1+alpha)/(2*T)
         rrc_win(ii) = 0;
     else
         rrc_win(ii) = 1/2*(1-sin(abs(pi*f(ii)*T/alpha)-pi/(2*alpha)))*exp(-1j*pi*f(ii)*T);
     end
         
end
end