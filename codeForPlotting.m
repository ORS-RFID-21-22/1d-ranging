figure;
plot(xvalues,yvalues,'-b','LineWidth',2);
hXLabel  = xlabel('x axis with units');
hYLabel  = ylabel('y-axis with units');
set(gca, ...
  'Box'         , 'off'     , ...
  'TickDir'     , 'out'     , ...
  'TickLength'  , [.03 .03] , ...
  'XMinorTick'  , 'off'      , ...
  'YMinorTick'  , 'off'      , ...
  'XGrid'       , 'on'      , ...
  'YGrid'       , 'on'      , ...
  'XColor'      , [.3 .3 .3], ...
  'YColor'      , [.3 .3 .3], ...
  'XTick'       ,0:5:100, ...
  'YTick'       , 0:5:100, ...
  'LineWidth'   , 2         );