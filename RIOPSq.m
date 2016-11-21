classdef RIOPS  < matlab.mixin.Copyable
    properties
        yyyy
        mm
        dd
        hh
        hhice
        data
        lat
        lon
        z
        t
        tStr
        roi
        scale
        depthLoaded  = false;
        latlonLoaded = false;
        iceConcLoaded = false;
        
        root = 'http://dd.weather.gc.ca/model_giops/netcdf/polar_stereographic/3d/00/024/';
    end
    methods
        
        function obj = RIOPS(yyyy,mm,dd,hh,hhice,roi,scale)
            obj.yyyy = yyyy;
            obj.mm = mm;
            obj.dd = dd;
            obj.hh = hh;
            obj.hhice = hhice;
            
            % If ROI is specified or empty, use default
            if (nargin < 6) || isempty(roi)
                obj.roi.lat = [63.5 76.5];
                obj.roi.lon = [-80.0 -52.0];
                obj.roi.name = 'BaffinBay';
            else
                obj.roi = roi;
            end
            if (~isfield(obj.roi, 'name'))
                obj.roi.name = 'region';
            end
            
            % If scale is specified or empty, use default
            if (nargin < 7 ) || isempty(scale)
                obj.scale.kscale = 2e5;
                obj.scale.lat = 62.0;
                obj.scale.lon = -56.0;
            else
                obj.scale = scale;
                if (~isfield(scale, 'kscale'))
                    obj.scale.kscale = 2e5;
                end
            end                        
        end
        
        % Get an individual RIOPS product
        function getProd(obj,prod)
            root = obj.root;
            yyyy = obj.yyyy;
            mm = obj.mm;
            dd = obj.dd;
            hh = obj.hh;
            hhice = obj.hhice;
            
            hasdepth = false;
            hasIceConc = false;
            
            switch (prod)
                case 'vosaline'
                    fn = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'votemper'
                    fn = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'vomecrty'
                    fn = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'vozocrtx'
                    fn = sprintf('CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'itzocrtx'
                    fn = sprintf('CMC_giops_%s_sfc_0_ps5km60N_3h-mean_%4d%02d%02d00_P%03d.nc',...
                        prod, yyyy, mm, dd, hhice);
                    hasIceConc = true;
                    
                case 'itzocrtx'
                    fn = sprintf('CMC_giops_%s_sfc_0_ps5km60N_3h-mean_%4d%02d%02d00_P%03d.nc',...
                        prod, yyyy, mm, dd, hhice);
                    hasIceConc = true;
            end
            
            % Get data and time from netcdf
            fpath = [root fn];
            %prodfile = [prod '.nc'];
            prodfile = fn;
            if (~exist(prodfile, 'file'))   % debug
                fprintf(1, '%s : downloading...', prod)
                fname = websave(prodfile, fpath);
            end  % debug
            fprintf(1, 'reading...')
            obj.data.(prod) = ncread(prodfile, prod);
            
            t = ncread(prodfile, 'time');
            obj.t = t/86400 + datenum('1950-01-01');
            obj.tStr = datestr(obj.t, 29);
            fprintf(1, 'done\n');
            
            % Get depth iff it hasn't been loaded and is available
            if (~obj.depthLoaded && hasdepth)
                obj.z = ncread(prodfile, 'depth');
                obj.depthLoaded = true;
            end
            
            % Get Ice concentration?
            if (~obj.iceConcLoaded && hasIceConc)
                iceconc = ncread(prodfile, 'iiceconc');
                iceconc(iceconc == 1e20) = NaN;
                obj.data.iceconc = iceconc;
            end
            
            % Do we have lat or lon yet?
            if (~obj.latlonLoaded)
                obj.lat = ncread(prodfile, 'latitude');
                obj.lon = ncread(prodfile, 'longitude');
                obj.latlonLoaded = true;
            end
            
        end
        
        function getCurrents(obj)
            getProd(obj, 'vozocrtx')
            getProd(obj, 'vomecrty');
        end
        
        function getIceVelocity(obj)
            getProd(obj, 'itzocrtx')
            getProd(obj, 'itzocrtx');
        end
        
        function hf = mapCurrents(obj, zlm, varargin)
            if nargin > 2
                hf = varargin(1);
            else
                hf = figure;
            end
            
            % Get data
            if (~isfield(obj.data, 'vozocrtx'))
                obj.getCurrents();
            end
            vx = obj.data.vozocrtx;
            vy = obj.data.vomecrty;
            lat = double(obj.lat);
            lon = double(obj.lon);
            z = obj.z;
            t = obj.t;
            tStr = obj.tStr;
            
            % Region to plot
            r = obj.roi;
            r.lon = r.lon + 360;
            gg = find(lat(:) >= r.lat(1) & lat(:) <= r.lat(2) & lon(:) >= r.lon(1) & lon(:) <= r.lon(2));
            
            % quiver scaling
            mscale = 0;        % m_quiver autscales arrow : 1 unit = 1 m/s per 1 deg latitude
            kscale = 3;        % ...so scale data directly
            
            % Arrow legend
            arrowLen = 0.1 ; % m/s
%             scale = obj.scale;
            scale.lat = 66.5;
            scale.lon = -77.5;
            slat = [scale.lat  scale.lat+kscale*arrowLen];
            slon = (scale.lon * [1 1]);
            if (scale.lon < 0)
                slon = slon + 360;
            end
            
            % Map projection
            m_proj('Albers', 'lon', r.lon, 'lat', r.lat, 'rect', 'off');
%             m_proj('Equidistant Cylindrical', 'lon', r.lon, 'lat', r.lat);

            % Generate coastline database subset once
            if (~exist('baffini.mat', 'file'))
                m_gshhs_i('save', 'baffini');
            end
            colormap(flipud(jet(8)));
            
            zlevels = find((obj.z >= zlm(1)) & (obj.z < zlm(2)));
            vxs = mean(vx(:,:,zlevels),3);
            vys = mean(vy(:,:,zlevels),3);
            
            titleStr = sprintf('%s Currents z = %.1f - %.1f m, %s', ...
                obj.roi.name, z(zlevels(1)), z(zlevels(end)), tStr);
            
            [cs, h] = m_etopo2('contourf', [-2000 -1000 -500]);
            set(h, 'LineStyle', 'none');
            cmap = colormap(summer);
            cmap = cmap*2.5;
            cmap(cmap>1) = 1;
            colormap(cmap);
            
            % Regrid
            dlat = 0.4;
            dlon = 0.4;
            latg = r.lat(1):dlat:r.lat(2);
            long = r.lon(1):dlon:r.lon(2);
            
            [Xg Yg] = meshgrid(long, latg);
            xq = griddata(lon, lat, vxs, Xg, Yg);
            yq = griddata(lon, lat, vys, Xg, Yg);
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
            changeFontSize(12);
            
            % Print
            set(hf, 'color', 'w', 'position', [360   186   561   512]);
            set(hf,'PaperPositionMode','auto','paperorientation', 'landscape');
            
        end
        
        function fileName = kmlCurrents(obj, zlm, color)
            
            % get flatColor option
            flatColor = [];
            if (nargin > 2)
                flatColor = color;
            end
            
            % Get data
            if (~isfield(obj.data, 'vozocrtx'))
                obj.getCurrents();
            end
            vx = obj.data.vozocrtx;
            vy = obj.data.vomecrty;
            lat = double(obj.lat);
            lon = double(obj.lon);
            z = obj.z;
            t = obj.t;
            tStr = obj.tStr;
            
            % Region to plot
            r = obj.roi;
            r.lon = r.lon + 360;
            gg = find(lat(:) >= r.lat(1) & lat(:) <= r.lat(2) & lon(:) >= r.lon(1) & lon(:) <= r.lon(2));
            
            % Quiver scaling
            kscale = obj.scale.kscale;
            
            % Quiver legend
            arrowLen = 0.1 ; % m/s
            slat = obj.scale.lat * [1 1 1 1];
            slon = (obj.scale.lon * [1 1 1 1]);
            if (obj.scale.lon < 0)
                slon = slon +360;
            end
            uscale = arrowLen*[0 2 0 -4];
            vscale = arrowLen*[1 0 -3 0];
            
            % Zlevels
            zlevels = find((obj.z >= zlm(1)) & (obj.z < zlm(2)));
            vxs = mean(vx(:,:,zlevels),3);
            vys = mean(vy(:,:,zlevels),3);
            
            % Regrid
            dlat = 0.4;
            dlon = 0.4;
            latg = r.lat(1):dlat:r.lat(2);
            long = r.lon(1):dlon:r.lon(2);
            
            [Xg Yg] = meshgrid(long, latg);
            xq = griddata(lon, lat, vxs, Xg, Yg);
            yq = griddata(lon, lat, vys, Xg, Yg);
            
            % Add on legend
            Xg = [Xg(:); slon(:)]';
            Yg = [Yg(:); slat(:)]';
            u = [xq(:); uscale(:)]';
            v = [yq(:); vscale(:)]';
            nans = isnan(Yg+Yg+u+v);
            Xg(nans) = []; Yg(nans) = [];
            u(nans) = [];  v(nans) = [];
            
            % Color scaling
            if (isempty(flatColor))
                N = numel(xq);
                M = 257;
                offset = 100;
                [~,mag] = cart2pol(u,v);
                mag = abs(mag);
                magMax = max(mag(:));
                magMax = 0.5;
                gmag = floor((mag/magMax)*M)+1;
		gmag = min(gmag, M);
                hf = figure;
                cmap = colormap(jet(M+offset));
                close(hf);
                cmap = cmap(offset:end, :);
%                disp(size(gmag));
%                disp(size(cmap));
                cmap = cmap(gmag,:);
            else
                cmap = flatColor;
            end
            
            % Quiver names
            kmlName = sprintf('%s Currents %.0f-%.0f m, %s', ...
                obj.roi.name, z(zlevels(1)), z(zlevels(end)), tStr);
            fileName = sprintf('%s-uv-%.0f-%.0f-%s.kmz', ...
                obj.roi.name, z(zlevels(1)), z(zlevels(end)), tStr);
            disp(fileName);
            
            % OpenEarth KMLquiver works.  KMLToolbox quiver is incorrect!
            OPT = KMLquiver(Yg, Xg, v, u, 'lineWidth', 1, 'lineColor', cmap, ...
                'kmlName', kmlName, 'fileName', fileName,'arrowScale', kscale, ...
                'arrowStyle', 'line', 'lineWidth', 1 );
            
            
        end
        
    end
    
end
