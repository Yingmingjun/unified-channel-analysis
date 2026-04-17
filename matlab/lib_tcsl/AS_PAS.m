function [mean_angle, var_angle] = AS_PAS(angle_vec,power_vec, SLT)

angle_vec = deg2rad(angle_vec);

SLmask1=(power_vec>-50);
SLmask2=(power_vec>SLT);

[mean_angle, var_angle]=circ_std(angle_vec,power_vec);