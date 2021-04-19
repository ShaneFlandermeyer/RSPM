% A class representing constant gamma model clutter.
%
% For this model, the are reflectivity of the clutter is given by
%
% sigma_0 = gamma*sin(psi_c)
%
% where gamma is a terrain-dependent paramter and psi_c is the grazing angle
classdef ConstantGammaClutter < Clutter
  
  properties (Dependent)
    gamma;              % Clutter gamma
    earth_model;        % Earth model (currently only supports flat)
    span_azimuth;       % Azimuth span of the whole clutter ring
    span_azimuth_patch; % Azimuth span of individual clutter patches
    num_patches;        % Number of clutter patches in range ring
  end
  
  properties (Access = protected)
    d_gamma;
    d_earth_model;
    d_span_azimuth;
    d_span_azimuth_patch;
  end
  
  %% Public methods
  methods (Access = public)
    
    function area = patchArea(obj,radar,range)
      % Calculate the area of each clutter patch at a given range ring
      
      % Clutter patch azimuth width
      width_az = 2*pi/obj.num_patches;
      % Clutter patch range extent
      width_range = radar.range_resolution;
      % Grazing/elevation angle for the FLAT EARTH case
      angle_graze = asin(radar.position(3)/range);
      % Area according to ward eq.(56)
      area = range*width_az*width_range*sec(angle_graze);
      
    end
    
    function sigma = patchRCS(obj,radar,range)
      % Calculate the clutter patch radar cross section for every patch in
      % the given range, assuming all patches have the same area
      patch_area = obj.patchArea(radar,range);
      % TODO: This grazing angle only applies for the flat earth model and
      %       the coordinate system with the origin directly below the radar
      grazing_angle = asin(radar.position(3)/range);
      sigma0 = obj.gamma*sin(grazing_angle);
      sigma = sigma0*patch_area;
    end
  end
  
  %% Setter Methods
  methods
    
    function set.gamma(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_gamma = val;
    end
    
    function set.earth_model(obj,val)
      validateattributes(val,{'string','char'},{});
      obj.d_earth_model = val;
    end
    
    function set.span_azimuth(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_span_azimuth = val;
    end
    
    function set.span_azimuth_patch(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_span_azimuth_patch = val;
    end
    
  end
  
  %% Getter Methods
  methods
    
    function out = get.num_patches(obj)
      out = obj.d_span_azimuth/obj.d_span_azimuth_patch;
    end
    
    function out = get.gamma(obj)
      out = obj.d_gamma;
    end
    
    function out = get.earth_model(obj)
      out = obj.d_earth_model;
    end
    
    function out = get.span_azimuth(obj)
      out = obj.d_span_azimuth;
    end
    
    function out = get.span_azimuth_patch(obj)
      out = obj.d_span_azimuth_patch;
    end
    
  end
end