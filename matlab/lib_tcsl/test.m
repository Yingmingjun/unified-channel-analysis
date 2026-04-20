% Given data points
x = 1:50; % Independent variable
y = linspace(db2pow(-40),db2pow(-53),15); % Dependent variable
y = linspace(-40,-53,15);

% Points to interpolate
%xq = db2pow(-50); % Query point
%xq = db2pow(-50);

% Perform linear interpolation
%yq = interp1(x, y, xq);

%disp(['Interpolated value at x = ', num2str(xq), ' is y = ', num2str(yq)]);
