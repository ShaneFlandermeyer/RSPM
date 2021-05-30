classdef BarrageJammer < AbstractJammer
  
  properties (Dependent)
    power_radiated_eff; % Effective radiated power (W/Hz)
  end
  
  properties (Access = protected)
    d_power_radiated_eff;
  end
  
  %% Constructors
  methods
    function obj = BarrageJammer()
      % Default Constructor
      
      % Add quantities that need to be converted when we change the scale
      % (linear <-> dB) or the angle unit (degree<->radian)
      obj.power_quantities = [obj.power_quantities;{'power_radiated_eff'}];
      obj.voltage_quantities = [obj.voltage_quantities];
      obj.angle_quantities = [obj.angle_quantities];
    end
  end
  %% Setter Methods
  methods
    
    function set.power_radiated_eff(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_power_radiated_eff = val;
    end
    
  end
  
  %% Getter methods
  methods
    function out = get.power_radiated_eff(obj)
      out = obj.d_power_radiated_eff;
    end
  end
  
end