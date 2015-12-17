function GLEAN = glean_group_lifetimes(GLEAN,settings)
% Group differences in state life times, across all states.
%
% GLEAN_GROUP_LIFETIMES(GLEAN,settings)
%
% Computes average state lifetimes for each session. Group differences 
% are computed between the networks matrices, and significance testing is
% achieved by random permutation of the group labels.
%
% REQUIRED INPUTS:
%   GLEAN     - An existing GLEAN analysis
%   settings  - Structure with the following fields:
%                 .design    - [sessions x regressors] design matrix 
%                              (must contain only 0s and 1s)
%                 .contrasts - [contrasts x regressors] matrix of contrasts 
%                              to compute 
%
% OUTPUTS:
%   GLEAN     - An existing GLEAN analysis with new results field
%               GLEAN.results.group_transitions, containing the
%               following fields:
%                 .netmats     - [groups x states x channels x channels] 
%                                network matrix for each frequency band
%                 .pvalues     - [contrasts x states x channels x channels] 
%                                p-values for each frequency band
%
% Adam Baker 2015


res = 'group_group_lifetimes';

% Check inputs:
% ...


% Remove existing results:
if isfield(GLEAN.results,res)
    GLEAN.results = rmfield(GLEAN.results,res);
end

num_sessions = size(settings.design,1);
num_contrasts = size(settings.contrasts,1);
num_perms = 1e4;

hmmstats = glean_hmm_stats(GLEAN);

lifetimes = nanmean(cat(1,hmmstats.MeanLifeTime))';
[~,~,~,tstats] = glean_glm(lifetimes,settings.design,settings.contrasts);

% Permutation testing:
permuted_tstats = zeros(num_perms,num_contrasts);
for perm = 1:num_perms
    permuted_design = settings.design(randperm(num_sessions),:);
    [~,~,~,permuted_tstats(perm,:,:)] = glean_glm(lifetimes,permuted_design,settings.contrasts);
end
    
% p-values from permutations:
pvalues = zeros(num_contrasts,1);
for c = 1:num_contrasts
    counts = sum(abs(tstats(c)) <= abs(permuted_tstats(:,c)));
    pvalues(c) = (counts + 1) / (num_perms + 1);
end


results.lifetimes  = lifetimes;
results.tstats     = tstats;
results.CI.lower   = squeeze(prctile(permuted_tstats,2.5));
results.CI.upper   = squeeze(prctile(permuted_tstats,97.5));
results.pvalues    = pvalues;

% Append results and settings to GLEAN:
GLEAN.results.(res) = results;
GLEAN.results.(res).settings  = settings;

% Save updated GLEAN:
save(GLEAN.name,'GLEAN');

end



