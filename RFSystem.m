% An abstract class representing a notional RF front end.

classdef (Abstract) RFSystem < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  %% Properties
  
  % Constants
  properties (Constant = true, Access = private)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  
  % Private properties
  properties (Access = private)
    
    initial_param; % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
    % List of parameters that should be updated when we change the scale
    % from linear to dB or vice versa
    power_quantities = {'loss_system','noise_fig'}; 
    voltage_quantities = {};
    
  end
  
  % Target properties
  properties (Access = public)
    
    scale = 'dB';      % Specify dB or linear units
    center_freq;       % Center frequency
    loss_system;       % System loss (dB)
    noise_fig;         % Noise figure (dB)
    temperature_noise; % Input noise temperature
    tx_power;          % Tx power
    wavelength;        % Carrier wavelength
    
  end % Public properties
  % Dependent properties
  properties (Dependent)
    
  end % Dependent Properties
  
  %% Setter Methods
  methods
    
    function set.center_freq(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.center_freq = val;
      obj.checkIfUpdated('center_freq',val);
    end
    
    function set.loss_system(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.loss_system = val;
    end
    
    function set.scale(obj,val)
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'linear',1)
        % Change all voltage/power quantities to linear scale
        obj.convertToLinear();
      elseif strncmpi(val,'db',1)
        % Change all voltage/power quantities to dB scale
        obj.convertTodB();
      end
      obj.scale = val;
    end
    
    function set.temperature_noise(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.temperature_noise = val;
    end
    
    function set.tx_power(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.tx_power = val;
    end
    
    function set.wavelength(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.wavelength = val;
      obj.checkIfUpdated('wavelength',val);
    end
    
  end
  
  %% Getter methods
  methods
    
  end
  
  %% Public Methods
  methods (Access = public)
    
  end % Public methods
  %% Private Methods
  methods (Access = private)
    
    function updateParams(obj, param_name, param_val)
      % No parameter value given. Exit immediately to avoid breaking things
      if isempty(param_val)
        return
      end
      
      switch (param_name)
        case 'center_freq'
          obj.wavelength = obj.const.c/obj.center_freq;
        case 'wavelength'
          obj.center_freq = obj.const.c/obj.wavelength;
      end
      
      % Original parameters have updated all its dependent parameters. We
      % can safely empty the list of parameters that have already been
      % updated for the next assignment
      if (strcmp(obj.initial_param, param_name))
        obj.updated_list = {};
      end
    end % updateParams()
    
    function checkIfUpdated(obj, param_name, param_val)
      if ~any(strcmp(param_name, obj.updated_list))
        obj.updated_list{end+1} = param_name;
        obj.updateParams(param_name, param_val);
      end
    end
    
    % Convert all parameters that are currently in linear units to dB
    function convertTodB(obj)
      for ii = 1:numel(obj.power_quantities)
        obj.(obj.power_quantities{ii}) = 10*log10(obj.(obj.power_quantities{ii}));
      end
      for ii = 1:numel(obj.voltage_quantities)
        obj.(obj.voltage_quantities{ii}) = 20*log10(obj.(obj.voltage_quantities{ii}));
      end
    end
    
    % Convert all parameters that are currently in dB to linear units
    function convertToLinear(obj)
      for ii = 1:numel(obj.power_quantities)
        obj.(obj.power_quantities{ii}) = 10^(obj.(obj.power_quantities{ii})/10);
      end
      for ii = 1:numel(obj.voltage_quantities)
        obj.(obj.voltage_quantities{ii}) = 10^(obj.(obj.voltage_quantities{ii})/20);
      end
    end
  end % Private methods
  %% Hidden Methods (DO NOT EDIT THESE)
  methods (Hidden)
    function value = properties( obj )
      propList = sort( builtin("properties", obj) );
      if nargout == 0
        disp(propList);
      else
        value = propList;
      end
    end
    function value = fieldnames( obj )
      value = sort( builtin( "fieldnames", obj ) );
    end
  end
  methods (Access = protected)
    function group = getPropertyGroups( obj )
      props = properties( obj );
      group = matlab.mixin.util.PropertyGroup( props );
    end
  end
end % class