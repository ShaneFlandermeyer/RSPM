classdef BarrageJammer < rspm.jamming.AbstractJammer
  
  properties (Dependent)
    effRadiatedPower; % Effective radiated power (W/Hz)
  end
  
  properties (Access = protected)
    d_effRadiatedPower;
  end
  
  %% Constructors
  methods
    function obj = BarrageJammer()
      % Default Constructor
      
      % Add quantities that need to be converted when we change the scale
      % (linear <-> dB) or the angle unit (degree<->radian)
      obj.powerQuantities = [obj.powerQuantities;{'effRadiatedPower'}];
      obj.voltageQuantities = [obj.voltageQuantities];
      obj.angleQuantities = [obj.angleQuantities];
    end
  end
  %% Setter Methods
  methods
    
    function set.effRadiatedPower(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_effRadiatedPower = val;
    end
    
  end
  
  %% Getter methods
  methods
    function out = get.effRadiatedPower(obj)
      out = obj.d_effRadiatedPower;
    end
  end
  
end