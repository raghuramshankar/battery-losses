clear;
clc;
close all;

%% load data
load('ocv_final.mat');
time_ocv = time;
load('pulse_0_5_c_13.mat');
load('rc2_cf_0_5_c.mat');

%% voltage limitations
v_max = 4.4;                                    % cut-over voltage
v_min = 3.0;                                    % cut-off voltage

%% resample ocv and soc
t1 = time_ocv(1);
t2 = time_ocv(end);
dt = 1;                                         % sample time
t = (t1:dt:t2) - t1;

ocv = interp1(time_ocv, ocv, t1:dt:t2);
soc = interp1(time_ocv, soc, t1:dt:t2);

s = length(time);

%% variables
Q = 16.8;
eta = 1.0;                                  % coulombic efficiency

n = 2;                                      % number of rc links
i_r = zeros(n, 1);
v_c = zeros(n, 1);
flag = 1;

%% compute soc
ind_init = soc(interp1(ocv, 1:length(ocv), V_batt_time(1), 'nearest'))
ind_init = interp1(soc, 1:length(soc), ind_init, 'nearest');
v_t(1) = ocv(ind_init);
z0 = soc(ind_init);
z = z0 - dt/(Q*3600)*eta*cumsum(I(1:end));

% manual fit
p = 14;
r0 = r0_cf(p);
r1 = r1_cf(p);
r2 = r2_cf(p);
% r3 = r3_cf(p);
c1 = c1_cf(p);
c2 = c2_cf(p);
% c3 = c3_cf(p);

r = [r1; r2];
c = [c1; c2];

%% compute terminal voltage
for j = 1:n
    f(j) = exp(-dt/(r(j)*c(j)));
end
for k = 1:s-1
    if flag == 1
        i_r(:, k+1) = diag(f)*i_r(:, k) + (1-f')*I(k);
        v_c(:, k) = i_r(:, k).*r;
        ind = interp1(soc, 1:length(soc), z(k), 'nearest');
        v_t(k+1) = ocv(ind) - sum(v_c(:, k)) - I(k).*r0;
        if v_t(k) < v_min
            fprintf('Reached lower voltage limit.');
            flag = 0;
        end
        if v_t(k) > v_max
            fprintf('Reached upper voltage limit.');
            flag = 0;
        end 
    end
end

%% compute rms error
v_t = reshape(v_t, size(V_batt_time));
rmse = 1000*sqrt(mean((V_batt_time - v_t).^2))     % [mV]

%% plot
figure(1);
hold on;
plot(time, v_t, 'r', 'LineWidth', 2)
hold on;
plot(time, V_batt_time, 'b', 'LineWidth', 2)
xlabel('Time [s]')
ylabel('Terminal Voltage [V]')
title('RC')
legend('RC', 'Physical', 'location', 'southeast')