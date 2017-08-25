function output = MRF_dict_match( input_dp, input_dict )
% do MRF dictionary construction/match
% used in conjunction with MRF processing

%   INPUT: input_dp.img_data = Nr x Nc x nSig matrix of MRF img data
%                 ".reduce = 1 then dictionary is reduced by SVD, else no
%          input_dict.dict_red = SVD compressed dictionary
%                   ".V_red = significant right singular vectors
%                   ".dict_list = table of dictionary parameters
%                   ".dict_norm = normalized full dictionary
%   OUTPUT: output.T1_map = T1_map
%                ".T2_map = T2_map
%                ".B1_map = B1_map
%                ".R_map = complex matrix is correlation map
%                ".dict_list = list of dictionary parameters that
%                   correspond to the entries in the dictionary
%                ".dict_fn = input dictionary filename
% assumes reduced dictionary space is already calculated
disp('Doing MRF dictionary match...');
tic;


imgComb = input_dp.img_AR_comb;
[Nr, Nc, ~] = size(imgComb);
T1_map = zeros(Nr,Nc);
T2_map = T1_map;
R_map = T1_map;
B1_map = T1_map;
M0_map = T1_map;

V_red = input_dict.V_red;
dict_red = input_dict.dict_red;
dict_list = input_dict.dict_list;
dict_norm = input_dict.dict_norm'; % note Hermitian

for ii = 1:Nr
    disp(['MRF Tx map generating, row ' num2str(ii)])
    for jj = 1:Nc
        
        test_v = squeeze(imgComb(ii,jj,:));
        test_v = test_v./sqrt(test_v'*test_v); % normalized
        if input_dp.reduce == 1
            testR_v = conj(test_v')*V_red; % project onto SVD space
            ipDT_v = dict_red*testR_v'; % dj Vk conj(xk)
        else
            ipDT_v = dict_norm*test_v(:);
        end
        
        [maxIP, idxMax] = max(ipDT_v);
        
        T1_map(ii,jj) = dict_list(idxMax,1);
        T2_map(ii,jj) = dict_list(idxMax,2);
        B1_map(ii,jj) = dict_list(idxMax,3);
        R_map(ii,jj) = maxIP;
        
        test_v = squeeze(imgComb(ii,jj,:)); % un-normalized 
        M0_map(ii,jj) = dict_norm(idxMax,:)*test_v(:);
        
    end
end

output.T1_map = T1_map;
output.T2_map = T2_map;
output.B1_map = B1_map;
output.R_map = R_map;
output.M0_map = M0_map;
output.dict_list = dict_list;
output.dict_fn = input_dict.fn;

t = toc;
disp(['Doing dictionary match complete. Elapse time is ' num2str(t) ' s.']);

