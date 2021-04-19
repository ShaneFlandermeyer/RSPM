% A class representing a rectangular aperture antenna

classdef RectangularAntenna < Antenna
  
  
  % Public API
  properties (Dependent)
    width;                   % Width of the antenna aperture
    height;                  % Height of the antenna aperture
    area;                    % Aperture area
    beamwidth_azimuth_3db;   % 3db beamwidth in azimuth
    beamwidth_elevation_3db; % 3db beamwidth in elevation
    power_gain;              % Power gain
  end
  
  % Properties that store the data
  properties (Access = protected)
    d_width;
    d_height;
  end
  
  %% Setters
  methods
    
    function set.width(obj,val)
      validateattributes(val,{'numeric'},{'positive'});
      obj.d_width = val;
    end
    
    function set.height(obj,val)
      validateattributes(val,{'numeric'},{'positive'});
      obj.d_height = val;
    end
    
  end
  
  %% Getters
  methods
    
    function width = get.width(obj)
      width = obj.d_width;
    end
    
    function height = get.height(obj)
      height = obj.d_height;
    end
    
    function area = get.area(obj)
      area = obj.width*obj.height;
    end
    
    function beamwidth = get.beamwidth_azimuth_3db(obj)
      beamwidth = 0.89*obj.wavelength/obj.width;
      if (strncmpi(obj.angle_unit,'Degrees',1))
        beamwidth = (180/pi)*beamwidth;
      end
    end
    
    function beamwidth = get.beamwidth_elevation_3db(obj)
      beamwidth = 0.89*obj.wavelength/obj.height;
      if (strncmpi(obj.angle_unit,'Degrees',1))
        beamwidth = (180/pi)*beamwidth;
      end
    end
    
    function gain = get.power_gain(obj)
      if strncmpi(obj.angle_unit,'Degrees',1)
        gain = 26e3/(obj.beamwidth_azimuth_3db*obj.beamwidth_elevation_3db);
      else
        gain = 7.9/(obj.beamwidth_azimuth_3db*obj.beamwidth_elevation_3db);
      end
      % Convert to dB if necessary
      if (strncmpi(obj.scale,'db',1))
        gain = 10*log10(gain);
      end
    end
    
    
  end
  
  %% Public methods
  methods (Access = public)
    
    
    function gain = normVoltageGain(obj,az,el)
      % Calculate the normalized antenna pattern gain for a given
      % azimuth/elevation
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
        
      if strncmpi(obj.angle_unit,'Radians',1)
        % Get the separable azimuth component
        az_pattern = sinc(obj.width/obj.wavelength*sin(az));
        % Get the separable elevation component
        el_pattern = sinc(obj.height/obj.wavelength*sin(el));
        gain = abs(az_pattern.*el_pattern);
        % If the angle is in the backlobe, attenuate it
        gain(abs(az) >= pi/2) = sqrt(obj.backlobe_attenuation)*gain(abs(az) >= pi/2);
      else 
        % Same calculations as above, but with az/el in degrees
        az_pattern = sinc(obj.width/obj.wavelength*sind(az));
        % Get the separable elevation component
        el_pattern = sinc(obj.height/obj.wavelength*sind(el));
        gain = abs(az_pattern.*el_pattern);
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