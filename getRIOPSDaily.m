
function [lat, lon, z,  t, sal, temp, vx, vy, vix, viy] = getRIOPSDaily(yyyy,mm,dd,hh, hhice)

% GIOPS 3D data (Temperature, Salinity, Velocity?) is available publicly at
% http://dd.weather.gc.ca/model_giops/netcdf  on polar stereographic grid 
% (5km grid distance or 0.2 deg lat/lon); Files are in CF-compliant Netcdfv4


prod = 'vosaline';
fsal = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
    prod, yyyy, mm, dd, hh);

prod = 'votemper';
ftemp = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
    prod, yyyy, mm, dd, hh);

prod = 'vomecrty';
fy = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
    prod, yyyy, mm, dd, hh);

prod = 'vozocrtx';
fx = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
    prod, yyyy, mm, dd, hh);

prod = 'itzocrtx';
fix = sprintf('CMC_giops_%s_sfc_0_ps5km60N_3h-mean_%4d%02d%02d00_P%03d.nc',...
    prod, yyyy, mm, dd, hhice);

prod = 'itmecrty';
fiy = sprintf('CMC_giops_%s_sfc_0_ps5km60N_3h-mean_%4d%02d%02d00_P%03d.nc',...
    prod, yyyy, mm, dd, hhice);

% Get data from netcdf
sal = ncread(fsal, 'vosaline');
temp = ncread(ftemp, 'votemper');
vx = ncread(fx,'vozocrtx');
vy = ncread(fy,'vomecrty');
z = ncread(fsal, 'depth');
t = ncread(fsal, 'time');
lat = ncread(fx, 'latitude');
lon = ncread(fx, 'longitude');
vix = ncread(fix, 'itzocrtx');
viy = ncread(fiy, 'itmecrty');

end