bin_edges_nSP = min(data):3:max(data);
observed_freq_nSP = histcounts(data, [bin_edges_nSP,32]);
expected_freq_nSP = numel(nSP)/numel(bin_edges_nSP);
[h_DU_nSP,p_DU_nSP,chi2st_DU_nSP]=chi2gof(bin_edges_nSP+1, 'frequency', observed_freq_nSP, 'expected', expected_freq_nSP)

%{
pd = makedist('Uniform','lower',1,'upper',30);
cdfplot(data);
hold on;
x = linspace(1, 30, 1000);
plot(x, cdf(pd, x), 'r--');
hold off;
%[HH, PP, ksstatTT] = kstest(data, 'CDF', pd);
dist = 'unif';
[HH, PP, ksstatTT] = adtest(data, 'Distribution', dist);
%}