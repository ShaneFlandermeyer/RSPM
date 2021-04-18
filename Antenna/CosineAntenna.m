% A class representation of an antenna element with a 2D cosine beampattern

classdef CosineAntenna < Antenna
  
  properties
    % Aperture area. For now, I'm not doing anything with this parameter
    % and it is only included to make this class concrete (since area is an
    % abstract parameter)
    area;
  end
  
  methods (Access = public)
    
    function gain = normVoltageGain(obj,az,el)
      % Calculate the normalized voltage pattern gain (including backlobe
      % attenuation) for the given azimuths and elevations
      %
      % INPUTS: 
      %  - az: An array of azimuth angles
      %  - el: An array of elevation angles
      %
      % OUTPUTS: 
      %  - gain: The normalized voltage pattern gain
      
      if nargin == 2
        % If only the azimuth angles are specified, assume zero elevation
        el = zeros(size(az));
      end
      
      % Compute everything in linear units, but convert back to db if
      % necessary
      was_db = false;
      if strncmpi(obj.scale,'dB',1)
        obj.scale = 'Linear';
        was_db = true;
      end
      
      if strncmpi(obj.angle_unit,'Radian',1)
        % Radian angles
        gain = abs(cos(az).*cos(el));
        % If the angle is in the backlobe, attenuate it
        gain(abs(az) >= pi/2) = sqrt(obj.backlobe_attenuation)*gain(abs(az) >= pi/2);
      else
        % Degree angles
        gain = abs(cosd(az).*cosd(el));
        % If the angle is in the backlobe, attenuate it
        gain(abs(az) >= 90) = sqrt(obj.backlobe_attenuation)*gain(abs(az) >= 90);
      end
      
      % Convert back to dB
      if was_db
        obj.scale = 'dB';
        gain = 20*log10(abs(gain));
      end
      
    end
  end
end