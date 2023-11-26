%% Author Information
% Written By: Dr. Eric Markvicka
% Modified By: Luke Freyhof
% Date: November 25, 2023

clc
clear all 
close all

d1 = 110;
l2 = 105;
l3 = 150;

c = @cos; 
s = @sin; 

%% Whiteboard Points
points = zeros(15, 4);
points(:, 1) = linspace(1, length(points), length(points)); % Point index number
points(:, 2) = [77.5; 67.5; 67.5; 57.5; 47.5; 47.5; 47.5; 17.5; 17.5; 17.5; 7.5; 7.5; 2.5; 2.5; 7.5]; % X coordinates of whiteboard points
points(:, 3) = 56; % Y coordinates of whiteboard points
points(:, 4) = [305; 315; 295; 305; 335; 305; 275; 335; 305; 275; 280; 275; 280; 275; 305]; % Z coordinates of whiteboard points

%% Character Points
six_index = [8 5 6 7 10 9 6]; % Points index for 6
six_points = zeros(length(six_index), 3);
for i = 1:length(six_index)
    six_points(i, 1) = points(six_index(i), 2); % Create the x column of the list of points used to draw the character
    six_points(i, 2) = points(six_index(i), 3); % Create the y column of the list of points used to draw the character
    six_points(i, 3) = points(six_index(i), 4); % Create the z column of the list of points used to draw the character
end

%% line 
% n = 4;
% x = linspace(-3, -2.5, n);
% m = 0;
% y_int = 1;
% y = m*x+y_int;

%% Waypoint Generation
n = 4;
six_waypoints = zeros(length(six_points) + (n - 2)*(length(six_points) - 1), 3); % Preallocate size of coordinates array including waypoints

for i = 1:length(six_points - 1)
    six_waypoints((i + (i - 1)*(n - 2)), 1) = six_points(i, 1); % Assign the original coordinate values to the x column in the waypoints array.  This spreads out the original points and leaves space for the new waypoints.
    six_waypoints((i + (i - 1)*(n - 2)), 2) = six_points(i, 2); % Assign the original coordinate values to the y column in the waypoints array.  This spreads out the original points and leaves space for the new waypoints.
    six_waypoints((i + (i - 1)*(n - 2)), 3) = six_points(i, 3); % Assign the original coordinate values to the z column in the waypoints array.  This spreads out the original points and leaves space for the new waypoints.
end

x_increment = zeros(length(six_points) - 1); % Preallocate the size for the x_increment vector
y_increment = zeros(length(six_points) - 1); % Preallocate the size for the y_increment vector
z_increment = zeros(length(six_points) - 1); % Preallocate the size for the z_increment vector
for i = 1:length(six_points) - 1
    x_increment(i) = (six_points(i+1, 1) - six_points(i, 1))/(n - 1); % Find the distance that should be between each set of waypoints
    for j = 1:(n - 2)
        six_waypoints((i + (i - 1)*(n - 2)) + j, 1) = six_points(i, 1) + j*(x_increment(i)); % Add the waypoints between the original values into the waypoint array
    end

    y_increment(i) = (six_points(i+1, 2) - six_points(i, 2))/(n - 1); % Find the distance that should be between each set of waypoints
    for j = 1:(n - 2)
        six_waypoints((i + (i - 1)*(n - 2)) + j, 2) = six_points(i, 2) + j*(y_increment(i)); % Add the waypoints between the original values into the waypoint array
    end

    z_increment(i) = (six_points(i+1, 3) - six_points(i, 3))/(n - 1); % Find the distance that should be between each set of waypoints
    for j = 1:(n - 2)
        six_waypoints((i + (i - 1)*(n - 2)) + j, 3) = six_points(i, 3) + j*(z_increment(i)); % Add the waypoints between the original values into the waypoint array
    end
end

%% IK way points
x = six_waypoints(:, 1); % Extract the x values from the waypoints array
y = six_waypoints(:, 2); % Extract the y values from the waypoints array
z = six_waypoints(:, 3); % Extract the z values from the waypoints array

[t1,t2,t3] = IK(d1,l2,l3,x,y,z); % Find the corresponding joint angles for the cartesian coordinate points in the waypoints array
theta = [t1 t2 t3]; % Combine the joint angles into one array

v_vals = zeros(size(theta));

v_tip = [1; 0]; % operational velocity

% find joint velocity given v_tip
for i = 1:n-2
    t1_val = t1(i+1);
    t2_val = t2(i+1);
    J = [- l2*s(t1_val + t2_val) - l1*s(t1_val), -l2*s(t1_val + t2_val);
         l2*c(t1_val + t2_val) + l1*c(t1_val),  l2*c(t1_val + t2_val)];

    v_vals(:,i+1) = J^-1*v_tip;
end

% time_vals = [0];
for i = 2:n
    time_vals(i) = (i-1)*.75;
end
time_n = 20;


%% plot way points and geometric path
figure(1), hold on
xlim([-l1-l2, l1+l2])
ylim([-l1-l2, l1+l2])
title('Position')
plot_way_points(x,y)
plot_line(x,y)
plot_robot(l1,l2,t1,t2)


%% trajectory generation
figure(2), hold on
title('Joint Space')
plot_way_points_angles(theta, time_vals, v_vals)

for j = 1:size(theta,2)-1
    for i = 1:size(theta,1)
    
        a = find_cubic(time_vals(j),time_vals(j+1),theta(i,j), theta(i,j+1),v_vals(i,j),v_vals(i,j+1));
        
        % plot trajectory
        time = linspace(time_vals(j), time_vals(j+1), time_n);
        theta_t{i} = a(4) + a(3)*time + a(2)*time.^2 + a(1)*time.^3;
        v_t{i} = a(3) + 2*a(2)*time + 3*a(1)*time.^2;
        a_t{i} = 2*a(2) + 6*a(1)*time;
        
        figure(2)
        plot_joint_space(time, theta_t{i}, v_t{i}, a_t{i}, i)
    end

    %% actual trajectory
    for idx = 1:numel(theta_t{1})
        [x_act(idx), y_act(idx)] = FK(l1,l2,theta_t{1}(idx),theta_t{2}(idx));
    end
    
    figure(1)
    plot(x_act,y_act, 'b', 'linewidth', 2) % waypoints

end

