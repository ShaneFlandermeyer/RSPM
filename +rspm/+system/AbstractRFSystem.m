% An abstract class representing a notional RF front end.
%
% Blame: Shane Flandermeyer

classdef (Abstract) AbstractRFSystem < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  %% Properties
  
  % Constants
  properties (Constant = true, Access = protected)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290,...
      'Re',6370000,'ae',(4/3)*6370000);
  end
  
  % Private properties
  properties (Access = private)
    % List of parameters that should be updated when we change the scale
    % from linear to dB or vice versa
    powerQuantities = {'systemLoss','noiseFig'};
    voltageQuantities = {};
  end
  
  % Class members exposed to the outside world
  properties (Dependent)
    noisePower;       % Noise power 
    txPower;          % PEAK transmit power
    scale;             % Specifies if the units are linear or in dB
    systemLoss;       % System loss factor
    noiseFig;         % System noise figure
    noiseTemperature; % Temperature for noise calculations
    bandwidth;         % Receiver bandwidth (at complex baseband = the samp rate)
    centerFreq;       % Operating frequency (Hz)
    wavelength;        % Operating wavelength (m)
    position;          % System position
    velocity;          % System velocity (m/s)
  end
  
  % Internally stored class members
  properties (Access = protected)
    d_scale = 'dB';
    d_systemLoss;
    d_noiseFig;
    d_noiseTemperature;
    d_bandwidth;
    d_centerFreq;
    d_wavelength;
    d_position;
    d_velocity;
    d_txPower;
  end
  
  %% Setter Methods
  methods
    
    function set.txPower(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_txPower = val;
    end
    
    function set.position(obj,val)
      
      validateattributes(val,{'numeric'},{'3d'})
      % Make it a column vector
      if isrow(val)
        val = val.';
      end
      if (val(1) ~= 0) || (val(2) ~= 0)
        err_msg = ['Object currently only supports coordinate system\n',...
          'with origin defined as directly below the platform ',...
          '(i.e., x = 0, y = 0)'];
        warning(sprintf(err_msg));
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
    
    function set.centerFreq(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_centerFreq = val;
      obj.d_wavelength = obj.const.c/val;
      if isprop(obj,'antenna') && ~isempty(obj.antenna)
        obj.antenna.centerFreq = val;
      end
      
    end
    
    function set.wavelength(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_wavelength = val;
      obj.d_centerFreq = obj.const.c/val;
      if (isprop(obj,'antenna')) && ~isempty(obj.antenna)
        obj.antenna.wavelength = val;
      end
      
    end

    function set.noiseFig(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_noiseFig = val;

    end

    function set.systemLoss(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_systemLoss = val;
      
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
 
    function set.noiseTemperature(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_noiseTemperature = val;
      
    end
   
    function set.bandwidth(obj,val)
      
      obj.d_bandwidth = val;
      % Make this the sample rate for any waveform object we may be using
      if isprop(obj,'waveform') && ~isempty(obj.waveform)
        obj.waveform.sampleRate = val;
      end
      
    end
    
  end
  %% Getter methods
  methods
    
    function out = get.centerFreq(obj)
      out = obj.d_centerFreq;
    end
    
    function out = get.wavelength(obj)
      out = obj.d_wavelength;
    end
    
    function out = get.txPower(obj)
      out = obj.d_txPower;
    end
    
    function out = get.position(obj)
      out = obj.d_position;
    end
    
    function out = get.velocity(obj)
      out = obj.d_velocity;
    end
    
    function power = get.noisePower(obj)
      if (strcmpi(obj.scale,'db'))
        obj.convertToLinear();
      end
      power = obj.const.k*obj.noiseTemperature*obj.bandwidth*obj.noiseFig;
      % Conversion to dB
      if (strcmpi(obj.scale,'db'))
        power = 10*log10(power);
        obj.convertTodB();
      end
    end
    
    function out = get.bandwidth(obj)
      if isprop(obj,'waveform') && isempty(obj.d_bandwidth)
        out = obj.waveform.sampleRate;
      else
        out = obj.d_bandwidth;
        
      end
    end
    
    function out = get.scale(obj)
      out = obj.d_scale;
    end
    
    function out = get.noiseTemperature(obj)
      out = obj.d_noiseTemperature;
    end
    
    function out = get.systemLoss(obj)
      out = obj.d_systemLoss;
    end
    
    function out = get.noiseFig(obj)
      out = obj.d_noiseFig;
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
        power = 10^(obj.noisePower/10);
      else
        power = obj.noisePower;
      end
      noise = (randn(size(data)) + 1i*randn(size(data)))*sqrt(power/2);
      out = data + noise;
    end
    
  end % Public methods
  %% Private Methods
  methods
    
    % Convert all parameters that are currently in linear units to dB
    function convertTodB(obj)
      for ii = 1:numel(obj.powerQuantities)
        obj.(obj.powerQuantities{ii}) = 10*log10(obj.(obj.powerQuantities{ii}));
      end
      for ii = 1:numel(obj.voltageQuantities)
        obj.(obj.voltageQuantities{ii}) = 20*log10(obj.(obj.voltageQuantities{ii}));
      end
    end
    
    % Convert all parameters that are currently in dB to linear units
    function convertToLinear(obj)
      
      for ii = 1:numel(obj.powerQuantities)
        obj.(obj.powerQuantities{ii}) = 10^(obj.(obj.powerQuantities{ii})/10);
      end
      
      for ii = 1:numel(obj.voltageQuantities)
        obj.(obj.voltageQuantities{ii}) = 10^(obj.(obj.voltageQuantities{ii})/20);
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
