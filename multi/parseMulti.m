% VARIABLES
%   offsets
%     num_samples_per_offset
%     mode_data [ 20cm; dev ]
%     mean_data [ 20cm; dev ]
%     stdev_data [ 20cm; dev ]
%     error_data [ 20cm; dev ]
%   num_detected_samples
%   num_true_detected_samples
%     true_mean_data            - without false detections
%     true_stdv_data            - without false detections
%     true_error_data           - without false detections
%   prob_detect
%   false_alarm
%   range_offset
%   corrected_false_det_data
%   error_normalized

% cftool
% '../../data-orss-measurements/041822 1D Multitag Ranging/test-data-mult 041822.csv'

clc; clear; close all;

imported_data = csvread(input('File name: ')); % csvread('trial1.csv');
num_offsets = size(imported_data, 1) / 2;

base_data = {};
data = {};

% everything is ordered, 5 to 95
offsets = NaN(1,num_offsets);
num_samples_per_offset = NaN(1,num_offsets);
mode_data = NaN(2,num_offsets); % [ 20cm; dev ]
mean_data = NaN(2,num_offsets); % [ 20cm; dev ]
stdev_data = NaN(2,num_offsets); % [ 20cm; dev ]
error_data = NaN(2,num_offsets); % [ 20cm; dev ]

for ind = 1:num_offsets
    % get index0 - range
    offsets(ind) = imported_data(ind*2,1);
end

base_correct = 0.2*ones(1,5);
offset_correct = base_correct - offsets./100;

% separate imported data and collect high level stats

for ind = 1:num_offsets
    % get index1 - number of samples
    num_samples_per_offset(ind) = imported_data(ind*2,2);
    
    % vertically concatenate sample values, removing 0s
    concise_samples = imported_data(ind*2,3:end);
    concise_samples(concise_samples == 0) = [];
    data{end+1} = concise_samples;
    
    % same as above but for the static tag (20cm)
    concise_samples = imported_data(ind*2-1,3:end);
    concise_samples(concise_samples == 0) = [];
    base_data{end+1} = concise_samples;
    
    % collect full-sample statistics
    mode_data(1,ind) = mode(base_data{end});
    mode_data(2,ind) = mode(data{end});
    mean_data(1,ind) = mean(base_data{end});
    mean_data(2,ind) = mean(data{end});
    stdev_data(1,ind) = std(base_data{end});
    stdev_data(2,ind) = std(data{end});
    error_data(1,ind) = mean_data(1,ind) - base_correct(ind);
    error_data(2,ind) = mean_data(2,ind) - offset_correct(ind);
end

% get number of detections per range
% FOR MULTI: ALL TAGS DETECTED (built into mmWave demo script)
num_detected_samples = NaN(1,num_offsets);
for ind = 1:size(data,2)
    num_detected_samples(ind) = size(data{ind},2);
end

% store data set containing false positives
false_det_base_data = base_data;
false_det_data = data;

% remove false detections per range
% get number of true detections per range
% get true mean and stdev per range (after removing false alarms)
num_true_detected_samples = NaN(2,num_offsets);
true_mean_data = NaN(2,num_offsets);
true_stdev_data = NaN(2,num_offsets);
true_error_data = NaN(2,num_offsets);
for offset_ind = 1:size(data,2)
    % bin range error is [-0.0275, 0.0275]
    minSamp = mode_data(1,offset_ind) - 0.0275;
    maxSamp = mode_data(1,offset_ind) + 0.0275;
        
    for sample_ind = flip(1:size(base_data{offset_ind},2)) % back-iterate
        sample = base_data{offset_ind}(sample_ind);
        
        if (~((sample >=minSamp) && (sample <= maxSamp)))
            base_data{offset_ind}(sample_ind) = [];
        end
    end
    
    num_true_detected_samples(1,offset_ind) = size(base_data{offset_ind},2);
    true_mean_data(1,offset_ind) = mean(base_data{offset_ind});
    true_stdev_data(1,offset_ind) = std(base_data{offset_ind});
    true_error_data(1,offset_ind) = ...
        true_mean_data(1,offset_ind) - offset_correct(offset_ind);
    
    
    
    minSamp = mode_data(2,offset_ind) - 0.0275;
    maxSamp = mode_data(2,offset_ind) + 0.0275;
    
    for sample_ind = flip(1:size(data{offset_ind},2)) % back-iterate
        sample = data{offset_ind}(sample_ind);
        
        if (~((sample >=minSamp) && (sample <= maxSamp)))
            data{offset_ind}(sample_ind) = [];
        end
    end
    
    num_true_detected_samples(2,offset_ind) = size(data{offset_ind},2);
    true_mean_data(2,offset_ind) = mean(data{offset_ind});
    true_stdev_data(2,offset_ind) = std(data{offset_ind});
    true_error_data(2,offset_ind) = ...
        true_mean_data(2,offset_ind) - base_correct(offset_ind);
end

% calculate probability of detection
% calculate probability of false alarm
prob_detect = NaN(2,num_offsets); % single value per offset
false_alarm = NaN(2,num_offsets);
for ind = 1:size(data,2)
    total = num_samples_per_offset(ind);
    actual_1 = num_true_detected_samples(1,ind);
    actual_2 = num_true_detected_samples(2,ind);
    fake_1 = num_detected_samples(ind) - num_true_detected_samples(1,ind);
    fake_2 = num_detected_samples(ind) - num_true_detected_samples(2,ind);
    
    prob_detect(1,ind) = actual_1 / total;
    prob_detect(2,ind) = actual_2 / total;
    false_alarm(1,ind) = fake_1 / total;
    false_alarm(2,ind) = fake_2 / total;
end

% 0.2876 - 20cm base value from ../range/range-data-values 033122.txt
range_offset_1 = mean(true_error_data(1,:));
range_offset_2 = mean(true_error_data(2,:));
% range_offset_1 = mean(true_error_data(1,1:end-1));
% range_offset_2 = mean(true_error_data(2,1:end-1));
corrected_false_det_base_data = {};
corrected_false_det_data = {};
for ind = 1:num_offsets
    corrected_false_det_base_data{end+1} = false_det_base_data{ind} - range_offset_1;
    corrected_false_det_data{end+1} = false_det_data{ind} - range_offset_2;
end

% % % calculate intensities of each unique "range" measurement
% % intensities = {};
% % smallest_intensity = -1;
% % for ind = 1:num_offsets
% %     % unique_measurements = unique(corrected_false_det_data{range_ind});
% %     % count_per_val = NaN(1,size(unique_measurements));
% %     % for unique_ind = 1:unique_measurements
% %     %     unique_val = unique_measurements(unique_ind);
% %     %     count_per_val(unique_ind) = 
% %     % end
% %     % intensities{end+1} = []
% %     [count,val] = groupcounts(corrected_false_det_data{ind}');
% %     intensities{end+1} = count / sum(count);
% %     smallest_intensity = min([ smallest_intensity, intensities{end}' ]);
% % end

% % trying to calculate log intensity
% % produces a pretty shawty graph
% log_intensities = {};
% for ind = 1:num_offsets
%     intensities{ind} = intensities{ind} ./ smallest_intensity;
%     log_intensities{end+1} = sign(intensities{ind}).*log(abs(intensities{ind}));
%     log_intensities{end} = log_intensities{end} ./ max(log_intensities{end});
% end

%% STATS
% sussy baka

absolute_corrected_error = [ mode_data(1,:)-range_offset_1;
                             mode_data(2,:)-range_offset_2 ];
relative_percent_error = ...
    (absolute_corrected_error - [ base_correct;offset_correct ]) ...
    ./ ([ base_correct;offset_correct ])

max_rel_percent_err = max(abs(relative_percent_error),[],2) % max by row instead of by col
min_rel_percent_err = min(abs(relative_percent_error),[],2) % max by row instead of by col

max_stdev = max(stdev_data,[],2) % max by row instead of by col
min_stdev = min(stdev_data,[],2) % max by row instead of by col

max_prob_det = max(prob_detect,[],2)
min_prob_det = min(prob_detect,[],2)
max_fa = max(false_alarm,[],2)
min_fa = min(false_alarm,[],2)


%% PRINTING VALUES

display(offsets);
display(num_samples_per_offset);
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
display(range_offset_1);
display(range_offset_2);
 
%% Multi-Tag Specific

offset_data = mean_data(2,:)-mean_data(1,:);
offset_calibrate = abs(offset_data(3));
offset_data = offset_data - offset_calibrate;
offset_data = -offset_data; % DATA IS BACKWARDS

figure;
plot(offsets,offset_data*100,'-bo','LineWidth',2);
xlim([-12.5,12.5]), ylim([-12.5,12.5]);
hXLabel  = xlabel('True Offset (cm)', 'FontSize', 16);
hYLabel  = ylabel('Estimated Offset (cm)', 'FontSize', 16);
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
  'XTick'       , offsets, ...
  'YTick'       , -15:5:15, ...
  'LineWidth'   , 2         );

offset_error = abs(offset_data*100-offsets);
display(offset_error);


%{
        MULTI-TRIAL BRACKETING
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

% prob_detect(isnan(prob_detect)) = 0;
% mycurve = fit(offsets', prob_detect', "exp1");
% display(mycurve);
% plot(mycurve); hold on;
temprange = offsets;
temppofd = prob_detect;
% temprange(end)=[];
% temppofd(temppofd == 0) = [];
% plot(offsets,prob_detect,'ob','LineWidth',2);

testcurve = fit(temprange', temppofd', "gauss1");
display(testcurve);

figure;
plot(testcurve); hold on;
plot(temprange,temppofd,'ob','LineWidth',2);

% plot(offsets,prob_detect,'ob','LineWidth',2);
hXLabel  = xlabel('Range (cm)', 'FontSize', 16);
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
  'XTick'       , [0,offsets,100], ...
  'YTick'       , 0:0.1:1, ...
  'LineWidth'   , 2         );
% legend(gca, 'off');
legend('Gaussian Fitted Curve', 'Data Points');

% https://www.mathworks.com/help/curvefit/curve-fitting.html
% https://www.mathworks.com/help/curvefit/list-of-library-models-for-curve-and-surface-fitting.html
% https://www.mathworks.com/help/curvefit/fit.html#bto2vuv-1-fitType

% -------------------------------------------------------------------------
% RANGE - FALSE ALARM RATE (PER RANGE)
% -------------------------------------------------------------------------
figure;
plot(offsets,false_alarm,'ob','LineWidth',2);
hXLabel  = xlabel('Range (cm)', 'FontSize', 16);
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
  'XTick'       , [0,offsets,100], ...
  'YTick'       , 0:max(false_alarm)/10:max(false_alarm), ...
  'LineWidth'   , 2         );

% -------------------------------------------------------------------------
% RANGE - AVERAGE ERROR PER RANGE 
% -------------------------------------------------------------------------
figure;
error_normalized = error_data-range_offset;
plot(offsets,error_normalized,'-ob','LineWidth',2);
% plot(offsets,true_error_data,'-ob','LineWidth',2);
hXLabel  = xlabel('Range (cm)', 'FontSize', 16);
hYLabel  = ylabel('Average Error (m)', 'FontSize', 16);
values = min(error_normalized)*2:(max(error_normalized)-min(error_normalized))/5:max(error_normalized)*2;
% values(end+1) = 0;
% values = sort(values);
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
  'XTick'       , [0,offsets,100], ...
  'YTick'       , -0.0125:0.0025:0.0125, ...
  'LineWidth'   , 2         );

%{
% commented out 3/31/22 - not needed in paper
% % -------------------------------------------------------------------------
% % RANGE - SCATTER OF SAMPLES (PER RANGE)
% % -------------------------------------------------------------------------
% figure; hold on;
% for ind = 1:length(offsets)
%     range = offsets(ind);
%     unique_vals = sort(unique(corrected_false_det_data{ind}));
%     % x = zeros(1,length(unique_vals)) + offsets(ind);
%     % s = scatter(x,unique_vals,'filled',  'MarkerFaceAlpha', intensities{ind});
%     % plot(range,corrected_false_det_data{ind},'.b','LineWidth',2);
%     for sample_ind = 1:length(unique_vals)
%         sample = unique_vals(sample_ind);
%         scatter(range,sample,25,'b','filled','MarkerFaceAlpha',...
%             intensities{ind}(sample_ind));
%     end
% end
% hXLabel  = xlabel('Range (cm)');
% hYLabel  = ylabel('Range Samples by Intensity');
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
%   'XTick'       , [0,offsets,100], ...
%   'YTick'       , 0:0.1:1, ...
%   'LineWidth'   , 2         );
% hold off;

% figure; hold on;
% for ind = 1:length(offsets)
%     range = offsets(ind);
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
%       'XTick'       , [0,offsets,100], ...
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

%}

%{
%% POST-PROC (PLOTTING MANIP)

log_prob_detect = log(temppofd);
% testcurve = fit(temprange', log_prob_detect', "poly1");
coeff = polyfit(temprange, log_prob_detect,1);
% display(testcurve)
% figure;
% plot(temprange, temppofd, temprange, log_prob_detect);


%%
% -------------------------------------------------------------------------
% LINEAR PLOT - LOG PROB DETECTION
% -------------------------------------------------------------------------
% testcurve = 
%      Linear model Poly1:
%      testcurve(x) = p1*x + p2
%      Coefficients (with 95% confidence bounds):
%        p1 =   -0.008863  (-0.01086, -0.006864)
%        p2 =      0.1342  (0.02508, 0.2434)
% figure;
% plot(temprange, temppofd);
bestFitx = 0:0.1:100;
% y = -0.008863 * x + 0.1342 + (0.9993-0.08992); % account for offset
bestFity = coeff(1)*bestFitx + coeff(2) + ...
    (temppofd(1) - (coeff(1)*temprange(1) + coeff(2)));

figure;
plot(bestFitx, bestFity); hold on;
plot(temprange,log_prob_detect+temppofd(1),'ob','LineWidth',2);

% plot(offsets,prob_detect,'ob','LineWidth',2);
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
  'XTick'       , [0,offsets,100], ...
  'YTick'       , 0:0.1:1, ...
  'LineWidth'   , 2         );
legend(gca, 'off');

%% 
% -> copied above <-
% -------------------------------------------------------------------------
% POLYNOMIAL PLOT - LINEAR PROB DETECTION
% -------------------------------------------------------------------------
testcurve = fit(temprange', temppofd', "gauss1");
display(testcurve);

figure;
plot(testcurve); hold on;
plot(temprange,temppofd,'ob','LineWidth',2);

% plot(offsets,prob_detect,'ob','LineWidth',2);
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
  'XTick'       , [0,offsets,100], ...
  'YTick'       , 0:0.1:1, ...
  'LineWidth'   , 2         );
legend(gca, 'off');

  %}
MULTI-TRIAL BRACKETING
  %}