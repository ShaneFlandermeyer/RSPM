% An abstract class representing a notional RF front end.
%
% Blame: Shane Flandermeyer

classdef (Abstract) RFSystem < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  %% Properties
  
  % Constants
  properties (Constant = true, Access = protected)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  
  % Private properties
  properties (Access = private)
    % List of parameters that should be updated when we change the scale
    % from linear to dB or vice versa
    power_quantities = {'loss_system','noise_fig'};
    voltage_quantities = {};
  end
  
  % Class members exposed to the outside world
  properties (Dependent)
    power_noise;       % Noise power 
    power_tx;          % PEAK transmit power
    scale;             % Specifies if the units are linear or in dB
    loss_system;       % System loss factor
    noise_fig;         % System noise figure
    temperature_noise; % Temperature for noise calculations
    bandwidth;         % Receiver bandwidth (at complex baseband = the samp rate)
    center_freq;       % Operating frequency (Hz)
    wavelength;        % Operating wavelength (m)
    position;          % System position
    velocity;          % System velocity (m/s)
  end
  
  % Internally stored class members
  properties (Access = protected)
    d_scale = 'dB';
    d_loss_system;
    d_noise_fig;
    d_temperature_noise;
    d_bandwidth;
    d_center_freq;
    d_wavelength;
    d_position;
    d_velocity;
    d_power_tx;
  end
  
  %% Setter Methods
  methods
    
    function set.power_tx(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_power_tx = val;
    end
    
    function set.position(obj,val)
      
      validateattributes(val,{'numeric'},{'3d'})
      % Make it a column vector
      if isrow(val)
        val = val.';
      end
      obj.d_position = val;
      
    end
    
    function set.velocity(obj,val)
      
      validateattributes(val,{'numeric'},{'3d'})
      % Make it a column vector
      if isrow(val)
        val = val.';
      end
      obj.d_velocity = val;
      
    end
    
    function set.center_freq(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_center_freq = val;
      obj.d_wavelength = obj.const.c/val;
      if isprop(obj,'antenna') && ~isempty(obj.antenna)
        obj.antenna.center_freq = val;
      end
      
    end
    
    function set.wavelength(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_wavelength = val;
      obj.d_center_freq = obj.const.c/val;
      if (isprop(obj,'antenna')) && ~isempty(obj.antenna)
        obj.antenna.wavelength = val;
      end
      
    end

    function set.noise_fig(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_noise_fig = val;

    end

    function set.loss_system(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_loss_system = val;
      
    end
   
    function set.scale(obj,val)
      
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Linear',1) && ~strncmpi(obj.scale,'Linear',1)
        obj.d_scale = 'Linear';
        obj.convertToLinear();
      elseif strncmpi(val,'dB',1) && ~strncmpi(obj.scale,'dB',1)
        obj.d_scale = 'dB';
        obj.convertTodB();
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
      obj.d_temperature_noise = val;
      
    end
   
    function set.bandwidth(obj,val)
      
      obj.d_bandwidth = val;
      % Make this the sample rate for any waveform object we may be using
      if isprop(obj,'waveform') && ~isempty(obj.waveform)
        obj.waveform.samp_rate = val;
      end
      
    end
    
  end
  %% Getter methods
  methods
    
    function out = get.center_freq(obj)
      out = obj.d_center_freq;
    end
    
    function out = get.wavelength(obj)
      out = obj.d_wavelength;
    end
    
    function out = get.power_tx(obj)
      out = obj.d_power_tx;
    end
    
    function out = get.position(obj)
      out = obj.d_position;
    end
    
    function out = get.velocity(obj)
      out = obj.d_velocity;
    end
    
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
    
    function out = get.bandwidth(obj)
      if isprop(obj,'waveform') && isempty(obj.d_bandwidth)
        out = obj.waveform.samp_rate;
      else
        out = obj.d_bandwidth;
        
      end
    end
    
    function out = get.scale(obj)
      out = obj.d_scale;
    end
    
    function out = get.temperature_noise(obj)
      out = obj.d_temperature_noise;
    end
    
    function out = get.loss_system(obj)
      out = obj.d_loss_system;
    end
    
    function out = get.noise_fig(obj)
      out = obj.d_noise_fig;
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
  methods
    
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
