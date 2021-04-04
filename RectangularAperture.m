% A class representing a rectangular aperture antenna

classdef RectangularAperture < Antenna
  
  
  % Public API
  properties (Dependent)
    width; % Width of the antenna aperture
    height; % Height of the antenna aperture
    area;
    beamwidth_azimuth_3db;
    beamwidth_elevation_3db;
    power_gain;
  end
  
  % Properties that store the data
  properties (Access = protected)
    d_width;
    d_height;
    %     d_area;
    %     d_beamwidth_azimuth_3db;
    %     d_beamwidth_elevation_3db;
    %     d_power_gain;
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
      if (strncmpi(obj.angle_unit,'Degree',1))
        beamwidth = (180/pi)*beamwidth;
      end
    end
    
    function beamwidth = get.beamwidth_elevation_3db(obj)
      beamwidth = 0.89*obj.wavelength/obj.height;
      if (strncmpi(obj.angle_unit,'Degree',1))
        beamwidth = (180/pi)*beamwidth;
      end
    end
    
    function gain = get.power_gain(obj)
      if strncmpi(obj.angle_unit,'Degree',1)
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
    
    % Calculate the normalized antenna pattern gain for a given
    % azimuth/elevation
    function gain = normPatternGain(obj,az,el)
      if strncmpi(obj.angle_unit,'Radian',1)
        % Get the separable azimuth component
        P_az = sinc(obj.width/obj.wavelength*sin(az));
        % Get the separable elevation component
        P_el = sinc(obj.height/obj.wavelength*sin(el));
      else 
        % Same calculations as above, but with az/el in degrees
        P_az = sinc(obj.width/obj.wavelength*sind(az));
        P_el = sinc(obj.height/obj.wavelength*sind(el));
      end
      % Get the composite pattern gain
      gain = P_az.*P_el;
      % Convert to dB if necessary
      if strncmpi(obj.scale,'dB',1)
        gain = 10*log10(gain);
      end
        
    end
  end
  
  
  
end