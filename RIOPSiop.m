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
        fnames
        
        root = 'http://dd.weather.gc.ca/model_giops/netcdf/polar_stereographic/';
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
                    obj.scale.kscale = 1e5;
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
                    fn = sprintf('3d/00/%03d/CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        hh, prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'votemper'
                    fn = sprintf('3d/00/%03d/CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        hh, prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'vomecrty'
                    fn = sprintf('3d/00/%03d/CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        hh, prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'vozocrtx'
                    fn = sprintf('3d/00/%03d/CMC_giops_%s_depth_all_ps5km60N_24h-mean_%4d%02d%02d00_P%03d.nc', ...
                        hh, prod, yyyy, mm, dd, hh);
                    hasdepth = true;
                    
                case 'itzocrtx'
                    fn = sprintf('2d/00/%03d/CMC_giops_%s_sfc_0_ps5km60N_3h-mean_%4d%02d%02d00_P%03d.nc',...
                        hhice, prod, yyyy, mm, dd, hhice);
                    hasIceConc = true;
                    
                case 'itmecrty'
                    fn = sprintf('2d/00/%03d/CMC_giops_%s_sfc_0_ps5km60N_3h-mean_%4d%02d%02d00_P%03d.nc',...
                        hhice, prod, yyyy, mm, dd, hhice);
                    hasIceConc = true;
            end
            
            % Get data and time from netcdf
            fpath = [root fn];
%             prodfile = [prod '.nc'];
            prodfile = fn(11:end);
            if (~exist(prodfile, 'file'))   % debug
                fprintf(1, '%s : downloading...', prod)
                fname = websave(prodfile, fpath);
            end  % debug
            fprintf(1, 'reading...')
            obj.data.(prod) = ncread(prodfile, prod);
            obj.fnames.(prod) = prodfile;
            
            t = ncread(prodfile, 'time');
            obj.t = t/86400 + datenum('1950-01-01');
            obj.tStr = datestr(obj.t, 29);
            fprintf(1, 'done\n');
            
            % Get depth iff it hasnot been loaded and is available
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
            getProd(obj, 'itmecrty');
        end
        
        function psName = mapIce(obj, color)
            if (nargin > 1)
                psName = obj.mapPlot('ice', [0,0], color);
            else
                psName = obj.mapPlot('ice', [0,0]);
            end
        end
        
        function psName = mapCurrents(obj, zlm, color)
            if (nargin > 2)
                psName = obj.mapPlot('uv', zlm, color);
            else
                psName = obj.mapPlot('uv', zlm);
            end
        end
        
        function psName = mapPlot(obj, type, zlm, varargin)

            % Create figure
            hf = figure;                
            
            % Get data
            switch type
                case 'uv'
                    if (~isfield(obj.data, 'vozocrtx'))
                        obj.getCurrents();
                    end
                    vx = obj.data.vozocrtx;
                    vy = obj.data.vomecrty;
                    typeStr = 'Currents';
                case 'ice'
                    if (~isfield(obj.data, 'itzocrtx'))
                        obj.getIceVelocity();
                    end
                    vx = obj.data.itzocrtx;
                    vy = obj.data.itmecrty;
                    typeStr = 'Ice Velocity';
            end

            % Get lat, lon, depth from object
            lat = double(obj.lat);
            lon = double(obj.lon);
            z = obj.z;
            t = obj.t;

            % Link file name to request in case date for ice is different than currents
            tStr = sprintf('%04d-%02d-%02d', obj.yyyy, obj.mm, obj.dd);
            
            % Region to plot
            r = obj.roi;
            r.lon = r.lon + 360;
            gg = find(lat(:) >= r.lat(1) & lat(:) <= r.lat(2) & lon(:) >= r.lon(1) & lon(:) <= r.lon(2));
            
            % quiver scaling
            mscale = 0;        % m_quiver autscales arrow : 1 unit = 1 m/s per 1 deg latitude
%             kscale = 3;        % ...so scale data directly
            kscale = 1.2;        % ...so scale data directly

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
            
            % Zlevels
            switch type
                case 'uv'
                    zlevels = find((obj.z >= zlm(1)) & (obj.z < zlm(2)));
                    vxs = mean(vx(:,:,zlevels),3);
                    vys = mean(vy(:,:,zlevels),3);
                    hStr = sprintf('%02dh', obj.hh);
                case 'ice'
                    vxs = vx;
                    vys = vy;
                    zlevels = 1;
                    z = 0;
                    hStr = sprintf('%03dh', obj.hhice);
            end
            
            titleStr = sprintf('%s %s z = %.1f - %.1f m, %s', ...
                obj.roi.name, typeStr, z(zlevels(1)), z(zlevels(end)), tStr);
            
            [cs, h] = m_etopo2('contourf', [-2000 -1000 -500]);
            set(h, 'LineStyle', 'none');
            cmap = colormap(summer);
            cmap = cmap*2.5;
            cmap(cmap>1) = 1;
            colormap(cmap);
            
            % Decimate
            skip = 3;
            Xg = lon(1:skip:end,1:skip:end);
            Yg = lat(1:skip:end,1:skip:end);
            xq = vxs(1:skip:end,1:skip:end);
            yq = vys(1:skip:end,1:skip:end);

            h = m_quiver(Xg, Yg, kscale*xq, kscale*yq, mscale);
            set(h, 'LineWidth', 0.01);
            
            % Quiver
            %     m_quiver(lon(g), lat(g), kscale*vxs(g), kscale*vys(g), mscale);
            
            hold on;
            h = m_plot(slon, slat, 'r-', 'LineWidth',0.1);
            ht = m_text(mean(slon)+0.3, mean(slat), sprintf('%d cm/s', arrowLen*100));
            set(ht, 'background', 'w');
            
            
            m_grid('color', 0.1*[1 1 1], 'LineStyle', 'none');
            m_usercoast('baffini', 'patch', [220 255 220]/255, 'edgecolor', 'k');
            title(titleStr);
            changeFontSize(12);
            
            % Print
            set(hf, 'color', 'w', 'position', [360   186    730    780]);
            set(hf,'PaperPositionMode','auto','paperorientation', 'portrait');
%            psName = sprintf('%s-%s-%.0f-%.0f-%s-%s.ps', ...
%			     obj.roi.name, type, z(zlevels(1)), z(zlevels(end)), tStr, hStr);
            psName = sprintf('%s-%s.ps', ...
			     obj.roi.name, tStr);
            disp(psName);
            print(hf, '-dpsc2', '-append', psName);
            close(hf);

        end
        
        function filename = kmlIce(obj, color)
            if (nargin > 1)
                filename = obj.kmlPlot('ice', [0,0], color);
            else
                filename = obj.kmlPlot('ice', [0,0]);
            end
        end
        
        function filename = kmlCurrents(obj, zlm, color)
            if (nargin > 2)
                filename = obj.kmlPlot('uv', zlm, color);
            else
                filename = obj.kmlPlot('uv', zlm);
            end
        end
        
        function fileName = kmlPlot(obj, type, zlm, color)

            % get flatColor option
            flatColor = [];
            if (nargin > 3)
                flatColor = color;
            end
            
            % Get data
            switch type
                case 'uv'
                    if (~isfield(obj.data, 'vozocrtx'))
                        obj.getCurrents();
                    end
                    vx = obj.data.vozocrtx;
                    vy = obj.data.vomecrty;
                    typeStr = 'Currents';
                case 'ice'
                    if (~isfield(obj.data, 'itzocrtx'))
                        obj.getIceVelocity();
                    end
                    vx = obj.data.itzocrtx;
                    vy = obj.data.itmecrty;
                    typeStr = 'Ice Velocity';
            end
            
            lat = double(obj.lat);
            lon = double(obj.lon);
            z = obj.z;
            t = obj.t;
            tStr = obj.tStr;
            
            % Region to plot
            r = obj.roi;
            r.lon = r.lon + 360;
            
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
            switch type
                case 'uv'
                    zlevels = find((obj.z >= zlm(1)) & (obj.z < zlm(2)));
                    vxs = mean(vx(:,:,zlevels),3);
                    vys = mean(vy(:,:,zlevels),3);
                    hStr = sprintf('%02dh', obj.hh);
                case 'ice'
                    vxs = vx;
                    vys = vy;
                    zlevels = 1;
                    z = 0;
                    hStr = sprintf('%03dh', obj.hhice);
            end
                        
            % Decimate
            skip = 4;
            Xg = lon(1:skip:end,1:skip:end);
            Yg = lat(1:skip:end,1:skip:end);
            xq = vxs(1:skip:end,1:skip:end);
            yq = vys(1:skip:end,1:skip:end);
            gg = find(Yg(:) >= r.lat(1) & Yg(:) <= r.lat(2) & Xg(:) >= r.lon(1) & Xg(:) <= r.lon(2));

            % Add on legend
            Xg = [Xg(gg); slon(:)]';
            Yg = [Yg(gg); slat(:)]';
            u = [xq(gg); uscale(:)]';
            v = [yq(gg); vscale(:)]';
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
                cmap = cmap(gmag,:);
            else
                cmap = flatColor;
            end
            
            % Quiver names
            kmlName = sprintf('%s %s %.0f-%.0f m, %s %s', ...
                obj.roi.name, typeStr, z(zlevels(1)), z(zlevels(end)), tStr, hStr);
            fileName = sprintf('%s-%s-%.0f-%.0f-%s-%s.kmz', ...
                obj.roi.name, type, z(zlevels(1)), z(zlevels(end)), tStr, hStr);
            disp(fileName);
            
            % OpenEarth KMLquiver works.  KMLToolbox quiver is incorrect!
            OPT = KMLquiver(Yg, Xg, v, u, 'lineWidth', 1, 'lineColor', cmap, ...
                'kmlName', kmlName, 'fileName', fileName,'arrowScale', kscale, ...
                'arrowStyle', 'line', 'lineWidth', 1 );
            
            
        end
        
        function deleteFiles(obj)
            fnames = fieldnames(obj.fnames);
            if ~isempty(fnames)
                for i = 1:length(fnames)
                    disp(['Deleting ' obj.fnames.(fnames{i})]);
                    delete(obj.fnames.(fnames{i}));
                end
            end
        end
        
           
        
    end
    
end
