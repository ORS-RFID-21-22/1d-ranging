% VARIABLES
%   ranges
%     num_samples_per_range
%     mode_data
%     mean_data
%     stdev_data
%     error_data
%   num_detected_samples
%   num_true_detected_samples
%     true_mean_data
%     true_stdv_data
%     true_error_data
%   prob_detect
%   false_alarm
%   range_offset
%   corrected_false_det_data

% '../../data-orss-measurements/030222 1D Ranging/full-data-range 030422.csv'

clc; clear; close all;

imported_data = csvread(input('File name: ')); % csvread('trial1.csv');
num_ranges = size(imported_data, 1);

data = {};

% everything is ordered, 5 to 95
ranges = NaN(1,num_ranges);
num_samples_per_range = NaN(1,num_ranges);
mode_data = NaN(1,num_ranges);
mean_data = NaN(1,num_ranges);
stdev_data = NaN(1,num_ranges);
error_data = NaN(1,num_ranges);

% separate imported data and collect high level stats
for ind = 1:size(imported_data,1)
    % get index0 - range
    ranges(ind) = imported_data(ind,1);
    
    % get index1 - number of samples
    num_samples_per_range(ind) = imported_data(ind,2);
    
    % vertically concatenate sample values, removing 0s
    concise_samples = imported_data(ind,3:end);
    concise_samples(concise_samples == 0) = [];
    data{end+1} = concise_samples;
    
    % collect full-sample statistics
    mode_data(ind) = mode(data{end});
    mean_data(ind) = mean(data{end});
    stdev_data(ind) = std(data{end});
    error_data(ind) = mean_data(ind) - ranges(ind)/100;
end

% get number of detections per range
num_detected_samples = NaN(1,num_ranges);
for ind = 1:size(data,2)
    num_detected_samples(ind) = size(data{ind},2);
end

% store data set containing false positives
false_det_data = data;

% remove false detections per range
% get number of true detections per range
% get true mean and stdev per range (after removing false alarms)
num_true_detected_samples = NaN(1,num_ranges);
true_mean_data = NaN(1,num_ranges);
true_stdev_data = NaN(1,num_ranges);
true_error_data = NaN(1,num_ranges);
for range_ind = 1:size(data,2)
    % bin range error is [-0.0275, 0.0275]
    minSamp = mode_data(range_ind) - 0.0275;
    maxSamp = mode_data(range_ind) + 0.0275;
        
    for sample_ind = flip(1:size(data{range_ind},2)) % back-iterate
        sample = data{range_ind}(sample_ind);
        
        if (~((sample >=minSamp) && (sample <= maxSamp)))
            data{range_ind}(sample_ind) = [];
        end
    end
    
    num_true_detected_samples(range_ind) = size(data{range_ind},2);
    true_mean_data(range_ind) = mean(data{range_ind});
    true_stdev_data(range_ind) = std(data{range_ind});
    true_error_data(range_ind) = ...
        true_mean_data(range_ind) - ranges(range_ind)/100;
end

% calculate probability of detection
% calculate probability of false alarm
prob_detect = NaN(1,num_ranges);
false_alarm = NaN(1,num_ranges);
for ind = 1:size(data,2)
    total = num_samples_per_range(ind);
    actual = num_true_detected_samples(ind);
    fake = num_detected_samples(ind) - num_true_detected_samples(ind);
    
    prob_detect(ind) = actual / total;
    false_alarm(ind) = fake / total;
end

range_offset = mean(true_error_data);
corrected_false_det_data = {};
for ind = 1:num_ranges
    corrected_false_det_data{end+1} = false_det_data{ind} - range_offset;
end

% calculate intensities of each unique "range" measurement
intensities = {};
smallest_intensity = -1;
for ind = 1:num_ranges
    % unique_measurements = unique(corrected_false_det_data{range_ind});
    % count_per_val = NaN(1,size(unique_measurements));
    % for unique_ind = 1:unique_measurements
    %     unique_val = unique_measurements(unique_ind);
    %     count_per_val(unique_ind) = 
    % end
    % intensities{end+1} = []
    [count,val] = groupcounts(corrected_false_det_data{ind}');
    intensities{end+1} = count / sum(count);
    smallest_intensity = min([ smallest_intensity, intensities{end}' ]);
end

% % trying to calculate log intensity
% % produces a pretty shawty graph
% log_intensities = {};
% for ind = 1:num_ranges
%     intensities{ind} = intensities{ind} ./ smallest_intensity;
%     log_intensities{end+1} = sign(intensities{ind}).*log(abs(intensities{ind}));
%     log_intensities{end} = log_intensities{end} ./ max(log_intensities{end});
% end

%% STATS

absolute_corrected_error = mode_data - range_offset;
relative_percent_error = (absolute_corrected_error - ranges./100) ...
    / (ranges ./ 100);

max_rel_percent_err = max(relative_percent_error)
min_rel_percent_err = min(relative_percent_error)

max_stdev = max(stdev_data)
min_stdev = min(stdev_data)

max_prob_det = max(prob_detect)
min_prob_det = min(prob_detect)
max_fa = max(false_alarm)
min_fa = min(false_alarm)


%% PRINTING VALUES

display(ranges);
display(num_samples_per_range);
display(mode_data);
display(mean_data);
display(stdev_data);
display(error_data);
display(num_detected_samples);
display(num_true_detected_samples);
display(true_mean_data);
display(true_stdev_data);
display(true_error_data);
display(prob_detect);
display(false_alarm);
display(range_offset);

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
% RANGE - PROBABILITY OF DETECTION (PER RANGE)
% -------------------------------------------------------------------------
figure;
plot(ranges,prob_detect,'ob','LineWidth',2);
hXLabel  = xlabel('Range (cm)');
hYLabel  = ylabel('Probability of Detection');
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
  'XTick'       , [0,ranges,100], ...
  'YTick'       , 0:0.1:1, ...
  'LineWidth'   , 2         );

% -------------------------------------------------------------------------
% RANGE - FALSE ALARM RATE (PER RANGE)
% -------------------------------------------------------------------------
figure;
plot(ranges,false_alarm,'ob','LineWidth',2);
hXLabel  = xlabel('Range (cm)');
hYLabel  = ylabel('Probability of False Alarm');
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
  'XTick'       , [0,ranges,100], ...
  'YTick'       , 0:max(false_alarm)/10:max(false_alarm), ...
  'LineWidth'   , 2         );

% -------------------------------------------------------------------------
% RANGE - AVERAGE ERROR PER RANGE 
% -------------------------------------------------------------------------
figure;
plot(ranges,error_data,'-ob','LineWidth',2);
hXLabel  = xlabel('Range (cm)');
hYLabel  = ylabel('Average Error (m)');
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
  'XTick'       , [0,ranges,100], ...
  'YTick'       , min(error_data)/2:(max(error_data)-min(error_data))/5:max(error_data)*2, ...
  'LineWidth'   , 2         );

% -------------------------------------------------------------------------
% RANGE - SCATTER OF SAMPLES (PER RANGE)
% -------------------------------------------------------------------------
figure; hold on;
for ind = 1:length(ranges)
    range = ranges(ind);
    unique_vals = sort(unique(corrected_false_det_data{ind}));
    % x = zeros(1,length(unique_vals)) + ranges(ind);
    % s = scatter(x,unique_vals,'filled',  'MarkerFaceAlpha', intensities{ind});
    % plot(range,corrected_false_det_data{ind},'.b','LineWidth',2);
    for sample_ind = 1:length(unique_vals)
        sample = unique_vals(sample_ind);
        scatter(range,sample,25,'b','filled','MarkerFaceAlpha',...
            intensities{ind}(sample_ind));
    end
end
hXLabel  = xlabel('Range (cm)');
hYLabel  = ylabel('Range Samples by Intensity');
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
  'XTick'       , [0,ranges,100], ...
  'YTick'       , 0:0.1:1, ...
  'LineWidth'   , 2         );
hold off;

% figure; hold on;
% for ind = 1:length(ranges)
%     range = ranges(ind);
%     plot(range,unique(corrected_false_det_data{ind}),'.b','LineWidth',2);
%     hXLabel  = xlabel('Actual Range (cm)');
%     hYLabel  = ylabel('Measured Range Points (cm)');
%     set(gca, ...
%       'Box'         , 'off'     , ...
%       'TickDir'     , 'out'     , ...
%       'TickLength'  , [.03 .03] , ...
%       'XMinorTick'  , 'off'      , ...
%       'YMinorTick'  , 'off'      , ...
%       'XGrid'       , 'on'      , ...
%       'YGrid'       , 'on'      , ...
%       'XColor'      , [.3 .3 .3], ...
%       'YColor'      , [.3 .3 .3], ...
%       'XTick'       , [0,ranges,100], ...
%       'YTick'       , 0:0.1:1, ...
%       'LineWidth'   , 2         );
% end

% need to do error as well
% scatter plot of each estimataed range
% true on x, recorded on y
% exponential fit for function? (e^(-alpha)) vs. range
% based on SNR - decays by roughly 

% groupcounts
% https://www.mathworks.com/matlabcentral/answers/96504-how-can-i-count-the-occurrences-of-each-element-in-a-vector-in-matlab
% https://www.mathworks.com/help/matlab/ref/scatter.html