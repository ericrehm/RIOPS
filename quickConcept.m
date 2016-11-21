
%%  Plot Baffin Bay Curents From RIOPS output

% ddir = '/Users/ericrehm/Documents/BBANC/CONCEPTS/RIOPS/';
ddir = '/Users/ericrehm/Documents/BBANC/CONCEPTS/TS2014/';

yyyy = 2016;
mm = 03;
dd = 10;
hh = 24;
hhice = 003;

[lat, lon, z,  t, sal, temp, vx, vy, vix, viy] ...
    = getRIOPSDaily(yyyy, mm, dd, hh, hhice);

r.lat = [65.6 76.5];
r.lon = [-80 -52];
r.lon = r.lon + 360
gg = find(lat(:) >= r.lat(1) & lat(:) <= r.lat(2) & lon(:) >= r.lon(1) & lon(:) <= r.lon(2));

lat = double(lat);
lon = double(lon);
t = t/86400 + datenum('1950-01-01');
tStr = datestr(t, 29);
%%
hf = figure;

g = gg(1:16:end);  % Reduce vector density
mscale = 0;        % m_quiver autscales arrow : 1 unit = 1 m/s per 1 deg latitude
kscale = 3;        % ...so scale data directly

% Arrow legend
arrowLen = 0.1 ; % m/s
slat = [66.5, 66.5+kscale*arrowLen];
slon = [-77.5, -77.5]+360;

% Map projection
m_proj('Albers', 'lon', r.lon, 'lat', r.lat, 'rect', 'off');

% Generate coastline database subset once
if (~exist('baffini.mat', 'file'))
    m_gshhs_i('save', 'baffini');
end
colormap(flipud(jet(8)));

for i = 1:1
    %     subplot(1,3,i);
    
    zlevels = [1:10] + (i-1)*10;
    %     vxs = mean(vx(:,:,zlevels),3);
    %     vys = mean(vy(:,:,zlevels),3);
    
    titleStr = sprintf('Baffin Bay Currents z = %.1f - %.1f m, %s', ...
        z(zlevels(1)), z(zlevels(end)), tStr);
    
    [cs, h] = m_etopo2('contourf', [-2000 -1000 -500]);
    set(h, 'LineStyle', 'none');
    cmap = colormap(summer);
    cmap = cmap*2.5;
    cmap(cmap>1) = 1;
    colormap(cmap);
    
    %     Regrid
    %     dlat = 0.4;
    %     dlon = 0.4;
    %     latg = r.lat(1):dlat:r.lat(2);
    %     long = r.lon(1):dlon:r.lon(2);
    %     [Xg Yg] = meshgrid(long, latg);
    %     xq = griddata(lon, lat, vxs, Xg, Yg);
    %     yq = griddata(lon, lat, vys, Xg, Yg);
    m_quiver(Xg, Yg, kscale*xq, kscale*yq, mscale);
    
    % Quiver
    %     m_quiver(lon(g), lat(g), kscale*vxs(g), kscale*vys(g), mscale);
    
    hold on;
    h = m_plot(slon, slat, 'r-', 'LineWidth',2);
    ht = m_text(mean(slon)+0.3, mean(slat), sprintf('%d cm/s', arrowLen*100));
    set(ht, 'background', 'w');
    
    
    m_grid('color', 0.1*[1 1 1], 'LineStyle', 'none');
    m_usercoast('baffini', 'patch', [220 255 220]/255, 'edgecolor', 'k');
    title(titleStr);
    %     changeFontSize(12);
end

% Print
set(hf, 'color', 'w', 'position', [360   186   791   512]);
set(hf,'PaperPositionMode','auto','paperorientation', 'landscape');

% Stereographic projection needs special m_grid call
% m_proj('stereographic', 'lon', mean(r.lon), 'lat', mean(r.lat), 'rad', 10);
% m_proj('stereographic', 'lat', 90, 'long', 360-60, 'radius', 30);
% m_grid('xtick',12,'tickdir','out','ytick',[70 80],'linest','-');m_quiver(lon(g), lat(g), x(g), y(g), scale);

%%

%%
hf = figure;

g = gg(1:16:end);  % Reduce vectory density
mscale = 0;        % m_quiver autscales arrow : 1 unit = 1 m/s per 1 deg latitude
kscale = 3;        % ...so scale data directly

% Arrow legend
arrowLen = 0.1 ; % m/s
slat = [66.5, 66.5+kscale*arrowLen];
slon = [-77.5, -77.5]+360;

% Map projection
m_proj('Albers', 'lon', r.lon, 'lat', r.lat)

% Generate coastline database subset once
if (~exist('baffini.mat', 'file'))
    m_gshhs_l('save', 'baffini');
end
colormap(flipud(jet(8)));


titleStr = sprintf('Baffin Bay Sea Ice Velocity, %s', ...
    tStr);

[cs, h] = m_etopo2('contourf', [-2000 -1000 -500]);
set(h, 'LineStyle', 'none');
cmap = colormap(summer);
cmap = cmap*2.5;
cmap(cmap>1) = 1;
colormap(cmap);

%     Regrid
vxs = vix;
vys = viy;
xiq = griddata(lon, lat, vxs, Xg, Yg);
yiq = griddata(lon, lat, vys, Xg, Yg);
m_quiver(Xg, Yg, kscale*xiq, kscale*yiq, mscale);

% Quiver
% m_quiver(lon(g), lat(g), kscale*vxs(g), kscale*vys(g), mscale);
hold on;
h = m_plot(slon, slat, 'r-', 'LineWidth',2);
ht = m_text(mean(slon)+0.3, mean(slat), sprintf('%d cm/s', arrowLen*100));
set(ht, 'background', 'w');


m_grid('color', 0.1*[1 1 1]);
m_usercoast('baffini', 'patch', 0.9*[1 1 1], 'edgecolor', 'k');
title(titleStr);
% changeFontSize(12);


% Print
set(hf, 'color', 'w', 'position', [360   186   791   512]);
set(hf,'PaperPositionMode','auto','paperorientation', 'landscape');
