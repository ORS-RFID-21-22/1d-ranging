% VARIABLES
%   angles
%     num_samples_per_angle
%     mode_data
%   num_detected_samples
%   num_true_detected_samples
%   prob_detect
%   false_alarm

%  '../../data-orss-measurements/040522 1D Orientation/full-data-orientation 040622.csv'

clc; clear; close all;

imported_data = csvread(input('File name: ')); % csvread('trial1.csv');
num_angles = size(imported_data, 1);

data = {};

% everything is ordered, 5 to 95
angles = NaN(1,num_angles);
num_samples_per_angle = NaN(1,num_angles);
mode_data = NaN(1,num_angles);

num_detected_samples = NaN(1,num_angles);

% separate imported data and collect high level stats
for ind = 1:size(imported_data,1)
    % get index0 - angle
    angles(ind) = imported_data(ind,1);
    
    % get index1 - number of samples
    num_samples_per_angle(ind) = imported_data(ind,2);
    
    % vertically concatenate sample values, removing 0s
    concise_samples = imported_data(ind,3:end);
    concise_samples(concise_samples == 0) = [];
    data{end+1} = concise_samples;
    
    % collect full-sample statistics
    mode_data(ind) = mode(data{end});
    num_detected_samples(ind) = size(data{ind},2);
end

% get number of detections per range
for ind = 1:size(data,2)
    num_detected_samples(ind) = size(data{ind},2);
end

% remove false detections per range
% get number of true detections per range
num_true_detected_samples = NaN(1,num_angles);
for range_ind = 1:size(data,2)
    % bin range error is [-0.0275, 0.0275]
    minVal = mode_data(range_ind) - 0.0275;
    maxVal = mode_data(range_ind) + 0.0275;
        
    for sample_ind = flip(1:size(data{range_ind},2)) % back-iterate
        sample = data{range_ind}(sample_ind);
        
        if (~((sample >=minVal) && (sample <= maxVal)))
            data{range_ind}(sample_ind) = [];
        end
    end
    
    num_true_detected_samples(range_ind) = size(data{range_ind},2);
end

% calculate probability of detection
% calculate probability of false alarm
prob_detect = NaN(1,num_angles);
false_alarm = NaN(1,num_angles);
for ind = 1:size(data,2)
    total = num_samples_per_angle(ind);
    actual = num_true_detected_samples(ind);
    fake = num_detected_samples(ind) - num_true_detected_samples(ind);
    
    prob_detect(ind) = actual / total;
    false_alarm(ind) = fake / total;
end

% from 1d ranging measurements
prob_detect(7) = 0.9030;
false_alarm(7) = 0.0091;

%% PRINTING VALS

% VARIABLES
display(angles);
display(num_samples_per_angle);
display(mode_data);
display(num_detected_samples);
display(num_true_detected_samples);
display(prob_detect);
display(false_alarm);

%% PLOTTING

% REFERENCE
% figure;
% plot(xvalues,yvalues,'-b','LineWidth',2);
% hXLabel  = xlabel('x axis with units');
% hYLabel  = ylabel('y-axis with units');
% set(gca, ...
%   'Box'         , 'off'     , ...
%   'TickDir'     , 'out'     , ...
%   'TickLength'  , [.03 .03] , ...
%   'XMinorTick'  , 'off'      , ...
%   'YMinorTick'  , 'off'      , ...
%   'XGrid'       , 'on'      , ...
%   'YGrid'       , 'on'      , ...
%   'XColor'      , [.3 .3 .3], ...
%   'YColor'      , [.3 .3 .3], ...
%   'XTick'       ,0:5:100, ...
%   'YTick'       , 0:5:100, ...
%   'LineWidth'   , 2         );

% -------------------------------------------------------------------------
% ORIENTATION - PROBABILITY OF DETECTION (PER ANGLE)
% -------------------------------------------------------------------------
figure;
plot(angles,prob_detect,'ob','LineWidth',2);
hXLabel  = xlabel('Angle (degrees)', 'FontSize', 16);
hYLabel  = ylabel('Probability of Detection', 'FontSize', 16);
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
  'XTick'       , [-30,angles,30], ...
  'YTick'       , 0:0.1:1, ...
  'LineWidth'   , 2         );

% -------------------------------------------------------------------------
% ORIENTATION - PROBABILITY OF FALSE ALARM (PER ANGLE)
% -------------------------------------------------------------------------
figure;
plot(angles,false_alarm,'ob','LineWidth',2);
hXLabel  = xlabel('Angle (degrees)', 'FontSize', 16);
hYLabel  = ylabel('Probability of False Alarm', 'FontSize', 16);
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
  'XTick'       , [-30,angles,30], ...
  'YTick'       , 0:max(false_alarm)/10:max(false_alarm)+max(false_alarm)/10, ...
  'LineWidth'   , 2         );


% need to do error as well
% scatter plot of each estimataed range
% true on x, recorded on y
% exponential fit for function? (e^(-alpha)) vs. range
% based on SNR - decays by roughly 
