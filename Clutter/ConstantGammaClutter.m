classdef ConstantGammaClutter < Clutter
  
  properties (Dependent)
    gamma;
    earth_model;
    span_azimuth;
    span_azimuth_patch;
    num_patches;
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
      % Break the 
      delta_phi = 2*pi/obj.num_patches;
      delta_r = radar.range_resolution;
      psi = asin(radar.position(3)/range);
      area = range*delta_phi*delta_r*sec(psi);
    end
    
    function sigma = patchRCS(obj,radar,range)
      patch_area = obj.patchArea(radar,range);
      grazing_angle = asin(radar.position(3)/range);
      sigma0 = obj.gamma*sin(grazing_angle);
      sigma = sigma0*patch_area;
    end
  end
  
  %% Setter Methods
  methods
    
    function set.gamma(obj,val)
      obj.d_gamma = val;
    end
    
    function set.earth_model(obj,val)
      obj.d_earth_model = val;
    end
    
    function set.span_azimuth(obj,val)
      obj.d_span_azimuth = val;
    end
    
    function set.span_azimuth_patch(obj,val)
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