%% Importing data
clear
clc
close all

% Data info
sensor  = 'gyroscope';
file    = 'gyro_test_data.txt';
fs      = 100;   % [Hz]
fprintf("Chosen file: %s\n",file)

% Choose start and end points
% make t1 = t2 = 0 if it is to use all the data set
t1 = 3.75;  % start measurement [h]
t2 = 13.5;  % stop  measurement [h]

% Setting relative path where the data is located
user = getenv('username');
addpath(['c:\users\',user,'\Downloads']);
addpath(['d:\users\',user,'\Downloads']);

% Importing data
tic
tmp = readmatrix(file);
fprintf("File successfully imported...")
toc

%% Data processing
 
% Constants
g =  9.80665; % m/s^2

% Data selection
if t1 == 0 && t2 ==0 
    data = tmp(:,1);
else
    data = tmp(t1*fs*3600:t2*fs*3600, 1);
end

% Temperature data check
% some data have temperature info as well
if size(data,2) == 2
    temp = tmp(:,2);
end

N = length(data);
t = linspace(0, (N-1)/fs, N);

%% Allan variance calculation

% Create array for Allan variance correlation periods
m = fun_tau_array(N, 100, "optimized");

fprintf('Total time span of signal: %.2f h\n', ...
    N/fs/60/60);
fprintf('Time span of signal used to calculate Allan variance: %.2f h\n', ...
    (2*m(end))/fs/60/60);

% Calculate Allan variance
%  
% It requires one of the following toolbox:
%   Sensor Fusion and Tracking Toolbox
%   Navigation Toolbox
[avar, taus] = allanvar(data, m, fs);
adev = sqrt(avar);

% Calculate Allan variance confidence limit
I = 1./sqrt(2.*(N./m-1));

%% Calculate noises and respective indexes
% This part is not working correctly yet.
% Our Allan variance has a different format due to 
% the low-pass filter we apply to the signal
[arw,bias,rrw,iN,iB,iK] = fun_allan_fit(taus, adev);

% Converting output units
switch sensor
    case 'gyroscope'
        fprintf('inside gyro\n')
        arw_out = arw/60;
        bias_out = bias;
        rrw_out = rrw*(60^3);

    case 'accelerometer'
        fprintf('inside acc\n')
        arw_out = arw*60;           % m/s^2/rt-Hz
        bias_out = bias*(60^2);     % m/s^2
        rrw_out = rrw*(60^3);       % m/s^3/rt-Hz?
end

%% Print out fitted values
fprintf('\nARW = %.2s\n', arw_out)
fprintf('Bias = %.2s\n', bias_out)
fprintf('RRW = %.2s\n', rrw_out)

%% Figures
gray = [.3 .3 .3];
figure('Units','centimeters','Position',[1 1 10 20])
% Plot Signal
subplot(3,1,1)
    hold on
    plot(t/60/60, data, 'color',[.3 .3 .3])
        xlabel('Time [h]')
        ylabel('Measurement')
    xline((2*m(end))/fs/60/60)
% Plot Allan variance
subplot(3,1,2)
    hold on
    plot(taus, adev,...
        'color',[.3 .3 .3],'LineWidth',1.5)
        set(gca,'YScale','log','XScale','log')
        xlabel('tau [s]')
        ylabel('Allan deviation')
    % Ploting Allan variance recovered points
    % ARW
    plot(taus(iN),adev(iN), ...
        '.','MarkerSize',10,'Color',gray)
    plot(taus,(arw./sqrt(taus)),...
        '--','Color',gray)
    text(taus(iN),adev(iN)*1.5, '$ARW{\times}60$',...
        'Interpreter','latex')
    % BIAS
    plot(taus(iB),adev(iB), ...
        '.','MarkerSize',10,'Color',gray)
    plot(taus,(bias*0.6643*ones(size(taus))),...
        '--','Color',gray)
    text(taus(iB)*0.6,adev(iB)*0.5, '$BIAS{\times}0.664$',...
        'Interpreter','latex')
    % RRW
    plot(3, rrw, ...
        '.','MarkerSize',10,'Color',gray)
    plot(taus, (rrw.*sqrt(taus/3)), ...
        '--','Color',gray)
    text(3*0.2, rrw*1.5, '$RRW$',...
        'Interpreter','latex')
% Plot Allan variance with confidence limits
subplot(3,1,3)
patch([taus; flip(taus)], ...
    [adev-adev.*I;  flip(adev+adev.*I)], ...
    gray,'LineStyle','none')
    set(gca,'YScale','log','XScale','log')
    alpha(0.2)
hold on
plot(taus, adev,...
    'color',gray,'LineWidth',1.2)
    set(gca,'YScale','log','XScale','log')
    xlabel('tau [s]')
    ylabel('Allan deviation')