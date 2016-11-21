% RIOPSdailyTempIce.m

% Use vector render
set(0, 'defaultFigureRenderer', 'painters');

% Depth averaging
% zsurf = [0 30];
% z200 = [0 200];
% z500 = [200 500];
% z1000 = [500 1000];

% Today 
disp(datestr(now, 31));
[yyyy mm dd] = datevec(now);

dd = 13;

% Earliest prediction: 24 h currents, 003 h ice velocity
hh = 24;
hhice = 003;
r = RIOPS(yyyy, mm, dd, hh, hhice);

% r.kmlIce();
% r.kmlCurrents(zsurf);
% r.kmlCurrents(z200, [0.8 0 0]);
% r.kmlCurrents(z500, [0 0.8 0]);
% r.kmlCurrents(z1000, [0 0.8 0.8]);
[hf, psName] = r.mapTempIce('IceConc');
[hf, psName] = r.mapTempIce('IceConcAMSR');
% r.mapCurrents(zsurf);
% r.mapCurrents(z200, [0.8 0 0]);
% r.mapCurrents(z500, [0 0.8 0]);
% psName = r.mapCurrents(z1000, [0 0.8 0.8]);
% r.deleteFiles();

clear r;

% Get ice at 24 h
% hh = 24;
% hhice = 024;
% r = RIOPS(yyyy, mm, dd, hh, hhice);
% % r.kmlIce();
% r.deleteFiles();
% clear r;

% Get currents and ice at 48 h
% hh = 48;
% hhice = 048;
% r = RIOPS(yyyy, mm, dd, hh, hhice);

% r.kmlIce();
% r.kmlCurrents(zsurf);
% r.kmlCurrents(z200, [0.8 0 0]);
% r.kmlCurrents(z500, [0 0.8 0]);
% r.kmlCurrents(z1000, [0 0.8 0.8]);
% r.deleteFiles();
% clear r;

% command = 'cp -pv *.kmz /var/www/websites/gliders/currents/archive/.';
% [status, result] = system(command);
% disp(result)

% command = 'rm -v /var/www/websites/gliders/currents/*.kmz;mv -v *.kmz /var/www/websites/gliders/currents/.';
% [status, result] = system(command);
% disp(result);

pdfName = regexprep(psName, '.ps', '.pdf');
command = ['pstoedit -f gs:pdfwrite ' psName ' ' pdfName];
[status, result] = system(command);
disp(result);

% command = 'rm -v *.ps';
% [status, result] = system(command);
% disp(result);

% command = 'cp -pv *.pdf /var/www/websites/gliders/currents/archive/.';
% [status, result] = system(command);
% disp(result)
% 
% command = 'rm -v /var/www/websites/gliders/currents/*.pdf;mv -v *.pdf /var/www/websites/gliders/currents/.';
% [status, result] = system(command);
% disp(result);

exit
