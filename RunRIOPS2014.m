% RIOPS Current maps

set(0, 'DefaultFigureRenderer', 'zbuffer')

yyyy = 2014 + [0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1];
mm = [7:12 1:12];
dd = [9, 13, 10, 8, 12, 10, 14, 11, 11, 8, 13, 10,08,12,09,14,11,09];

zz = [0 30; 0 200; 200 500; 500 1000];
N = length(yyyy);

amsr = AMSR(6);

% for i = [11 12 1 2 3 4]
% for i = 1:6     % 2014
for i = 7:18   % 2015
    
    fprintf(1, '%04d%02d%02d ... \n', yyyy(i), mm(i), dd(i));
    
    r = RIOPS2(yyyy(i), mm(i), dd(i),0,0);
    
    for j = 1:4
        hf = figure;
        r.mapCurrents(zz(j,:), hf);
        
        amsr.readIce(yyyy(i),mm(i), dd(i));
        [cs,h] = amsr.mapIce(10);
        
         print(hf, '-dpsc2', '-append', 'RIOPS2015');
         close(hf);
    end
         clear r;
    
end
