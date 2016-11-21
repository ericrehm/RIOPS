
root = 'http://dd.weather.gc.ca/model_giops/netcdf/polar_stereographic/3d/00/024/';
fcrty = 'CMC_giops_vomecrty_depth_all_ps5km60N_24h-mean_2016032800_P024.nc';

fy = [root fcrty];
fname = websave('vomecrty.nc', fy);
vy = ncread('vomecrty.nc','vomecrty');

