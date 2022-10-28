function m = fun_tau_array(N, pts, optm)
%% Function to generate time array for Allan variance
% optm = "optimized" --> logspace array
% optm = "all" --> complete array

%     max_m = 2^floor(log2(N/2));     % Max m in power of 2
    max_m = (N-1)/2;
    if optm == "all" 
        m = 2:max_m;
    elseif optm == "optimized" 
        m = logspace(0, log10(max_m), pts)';
    end
    m = ceil(m);        
    m = unique(m);

end