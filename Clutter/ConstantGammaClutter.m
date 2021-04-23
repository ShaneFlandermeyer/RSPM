% A class representing constant gamma model clutter.
%
% For this model, the are reflectivity of the clutter is given by
%
% sigma_0 = gamma*sin(psi_c)
%
% where gamma is a terrain-dependent paramter and psi_c is the grazing angle
classdef ConstantGammaClutter < AbstractClutter
  
  properties (Dependent)

    gamma;              % Clutter gamma

  end
  
  properties (Access = protected)
    
    d_gamma;

  end
  
  %% Public methods
  methods (Access = public)
    
    function sigma = patchRCS(obj,radar)
      % Compute the radar cross section of each clutter patch in the 
      % range ring
      
      if ~strcmpi(obj.earth_model,'Flat')
        error('The assumptions for this computation currently only hold for the flat earth model.')
      end
      
      % Make a copy of the object so we don't change the real object's state
      clutter = copy(obj);
      clutter.scale = 'Linear';
      patch_area = clutter.patchArea(radar);
      angle_graze = asin(radar.position(3)/clutter.range);
       
      % Compute the patch RCS using Ward eq. (56)
      sigma0 = clutter.gamma*sin(angle_graze);
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