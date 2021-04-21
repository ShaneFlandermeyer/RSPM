% A class representing constant gamma model clutter.
%
% For this model, the are reflectivity of the clutter is given by
%
% sigma_0 = gamma*sin(psi_c)
%
% where gamma is a terrain-dependent paramter and psi_c is the grazing angle
classdef ConstantGammaClutter < AbstractClutter
  
  properties (Dependent)

    gamma;              % AbstractClutter gamma

  end
  
  properties (Access = protected)
    
    d_gamma;

  end
  
  %% Public methods
  methods (Access = public)
    
    function sigma = patchRCS(obj,radar)
      
      % Calculate the clutter patch radar cross section for every patch in
      % the given range, assuming all patches have the same area
      patch_area = obj.patchArea(radar);
      % TODO: This grazing angle only applies for the flat earth model and
      %       the coordinate system with the origin directly below the radar
      angle_graze = asin(radar.position(3)/obj.range);
      sigma0 = obj.gamma*sin(angle_graze);
      sigma = sigma0*patch_area;
      
    end

  end
  
  %% Setter Methods
  methods

    function set.gamma(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_gamma = val;
      
    end
    
  end
  
  %% Getter Methods
  methods
    
    function out = get.gamma(obj)
      
      out = obj.d_gamma;
      
    end
    
  end
  
end