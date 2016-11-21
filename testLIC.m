n = 256;    % size of the image
sigma = 60; % regularity of the vector field
options.bound = 'sym'; % boundary handling
v = perform_blurring(randn(n,n,2), sigma, options);
v = perform_vf_normalization(v);
% Now we perform the LIC of an initial noise image along the flow.

M = randn(n);
% parameters for the LIC
options.histogram = 'linear'; % keep contrast fixed
options.verb = 0;
options.dt = 1.5; % time steping
% size of the features
options.flow_correction = 1;
options.niter_lic = 2; % several iterations gives better results
% iterated lic
Mlist = {};
for i=1:4
    options.M0 = M;
    Mlist{end+1} = perform_lic(v, i*4, options);
end
% display
figure;
clf; imageplot(Mlist,'',2,2);