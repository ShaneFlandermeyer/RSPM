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
    loss_system;       % System loss (dB)
    noise_fig;         % Noise figure (dB)
    temperature_noise; % Input noise temperature
    bandwidth;         % System bandwidth
  end % Public properties
  
  % Dependent properties
  properties (Dependent)
    power_noise;
    
  end % Dependent Properties
  
  %% Setter Methods
  methods
    
    function set.loss_system(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.loss_system = val;
    end
    
    % Set the scale to dB or Linear
    function set.scale(obj,val)
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'linear',1) && ~strncmpi(obj.scale,'linear',1)
        % Change all voltage/power quantities to linear scale
        obj.convertToLinear();
        obj.scale = 'Linear';
        
      elseif strncmpi(val,'db',1) && ~strncmpi(obj.scale,'db',1)
        % Change all voltage/power quantities to dB scale
        obj.convertTodB();
        obj.scale = 'dB';
        
      end
      % Change sub-objects to linear units if any exist
      props = properties(obj);
      for ii = 1:length(props)
        if isobject(obj.(props{ii})) && isprop(obj.(props{ii}),'scale')
          obj.(props{ii}).scale = val;
        end
      end
    end
    
    function set.temperature_noise(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.temperature_noise = val;
    end
    
  end
  %% Getter methods
  methods
    function power = get.power_noise(obj)
      if (strcmpi(obj.scale,'db'))
          obj.convertToLinear();
      end
      power = obj.const.k*obj.temperature_noise*obj.bandwidth*obj.noise_fig;
      % Conversion to dB
      if (strcmpi(obj.scale,'db'))
        power = 10*log10(power);
        obj.convertTodB();
      end
    end
    
  end
  
  %% Public Methods
  methods (Access = public)
    
    function out = addThermalNoise(obj,data)
      % Adds thermal noise to the given data based on the noise power for the
      % system. 
      % 
      % INPUTS:
      %  - data: The data that the noise should be added to. There are no shape
      %          requirements for this input
      % OUTPUT: The noisy data
      if (strcmpi(obj.scale,'db'))
        power = 10^(obj.power_noise/10);
      else
        power = obj.power_noise;
      end
      noise = (randn(size(data)) + 1i*randn(size(data)))*sqrt(power/2);
      out = data + noise;
    end
    
  end % Public methods
  %% Private Methods
  methods (Access = private)
    
    function updateParams(obj, param_name, param_val)
      % No parameter value given. Exit immediately to avoid breaking things
      if isempty(param_val)
        return
      end
      
      switch param_name
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
        if isempty(obj.updated_list)
          obj.initial_param = param_name;
        end
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
      % Put the properties list in sorted order
      propList = sort( builtin("properties", obj) );
      % Move any control switch parameters to the top of the output
      switches = {'scale', 'const'}';
      propList(ismember(propList,switches)) = [];
      propList = cat(1,switches,propList);
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
