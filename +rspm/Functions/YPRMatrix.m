% Compute the rotation matrix for the given yaw, pitch and roll angles.
%
% Blame: Shane Flandermeyer

function R = YPRMatrix(yaw,pitch,roll,units)

% Handle default arguments and empty inputs
if nargin < 4 || units == ""
  units = 'Radians';
end
if nargin < 3 || isempty(roll)
  roll = 0;
end
if nargin < 2 || isempty(pitch)
  pitch = 0;
end
if nargin < 1 || isempty(yaw)
  yaw = 0;
end

% If the angles were given in degrees, convert them to radians for the
% calculation
if strncmpi(units,'Degrees',1)
  yaw = (pi/180)*yaw;
  pitch = (pi/180)*pitch;
  roll = (pi/180)*roll;
end

% Yaw matrix
R_yaw = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
% Pitch matrix
R_pitch = [cos(pitch) 0 sin(pitch); 0 1 0; -sin(pitch) 0 cos(pitch)];
% Roll matrix
R_roll = [1 0 0; 0 cos(roll) -sin(roll); 0 sin(roll) cos(roll)];
% Composite rotation matrix
R = R_yaw*R_pitch*R_roll;

end