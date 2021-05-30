% A class representing a single antenna element.
%
% Blame: Shane Flandermeyer

classdef (Abstract) AbstractAntenna < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  %% Properties
  
  % Constants
  properties (Constant = true, Access = private)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  
  % Private properties
  properties (Access = private)
    % A list of antenna parameters that are angles, used when switching
    % between radian mode and degree mode
    angle_quantities = {'azimuth','elevation'};
    power_quantities = {'backlobe_attenuation'};
    voltage_quantities = {};
  end
  
  % Visible properties
  properties (Dependent)
    angle_unit;           % Specify parameters in radian or degree
    scale;                % Specify parameters in dB or radian
    azimuth;              % Azimuth angle of the antenna aperture w.r.t the x axis
    elevation;            % Elevation angle of the antenna aperture
    mainbeam_direction;   % Cartesian (XYZ) antenna beam unit vector
    position;             % Cartesian (XYZ) antenna position
    center_freq;          % Center frequency
    tx_power;             % Tx power
    wavelength;           % Carrier wavelength
    backlobe_attenuation; % Backlobe power attenuation factor
  end
  
  % Hidden properties that store data
  properties (Access = protected)
    d_angle_unit = 'Radians'; 
    d_scale = 'dB'; 
    d_azimuth; 
    d_elevation;
    d_mainbeam_direction; 
    d_position; 
    d_center_freq;       
    d_tx_power;          
    d_wavelength;     
    d_backlobe_attenuation = 0;
  end
  
  % Abstract properties
  properties (Abstract)
    area; % Aperture area
  end
  
  % Abstract methods
  methods (Abstract)
    gain = normVoltageGain(obj,az,el);
  end
  
  %% Constructors
  methods
    
    function obj = AbstractAntenna(size)
      % Default constructor
      if (nargin > 0)
        % Output an array or matrix of antenna elements
        % TODO: Check for valid inputs before doing this
        obj = repmat(obj,size);
      end
    end
    
  end
  %% Setter methods
  methods
    
    function set.backlobe_attenuation(obj,val)
      
      validateattributes(val,{'numeric'},{'scalar','nonnan'});
      obj.d_backlobe_attenuation = val;
      
    end
    
    function set.scale(obj,val)
      
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'linear',1) && ~strncmpi(obj.scale,'Linear',1)
        % Change all voltage/power quantities to linear scale
        obj.convertToLinear();
        obj.d_scale = 'Linear';
      elseif strncmpi(val,'db',1) && ~strncmpi(obj.scale,'dB',1)
        % Change all voltage/power quantities to dB scale
        obj.convertTodB();
        obj.d_scale = 'dB';
      end
      
    end
    
    function set.angle_unit(obj,val)
      
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Degrees',1) && ~strncmpi(obj.angle_unit,'Degrees',1)
        % Convert angle measures to degree
        obj.d_angle_unit = 'Degrees';
        obj.convertToDegree();
      elseif strncmpi(val,'Radians',1) && ~strncmpi(obj.angle_unit,'Radians',1)
        % Convert angle measures to radians
        obj.d_angle_unit = 'Radians';
        obj.convertToRadian();
      end
      
    end
    
    function set.azimuth(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_azimuth = val;
      
    end
    
    function set.elevation(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_elevation = val;
      
    end
    
    function set.mainbeam_direction(obj,val)
      
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      if isrow(val) % Make this a column vector
        val = val.';
      end
      val = val ./ norm(val); % Normalize to unit vector
      obj.d_mainbeam_direction = val; % Set object property
      [obj.azimuth,obj.elevation] = ...
        cart2sph(obj.mainbeam_direction(1),...
        obj.mainbeam_direction(2),obj.mainbeam_direction(3));
      
    end
    
    function set.tx_power(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_tx_power = val;
      
    end
    
    function set.wavelength(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_wavelength = val;
      obj.d_center_freq = obj.const.c/obj.wavelength;
      
    end
    
    function set.center_freq(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_center_freq = val;
      obj.d_wavelength = obj.const.c/obj.center_freq;
      
    end
    
    function set.position(obj,val)
      
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      if isrow(val) % Make this a column vector
        val = val.';
      end
      if norm(val) ~= 0
        val = val ./ norm(val);
      end
      obj.d_position = val;
    end
      
  end
  
  %% Getter methods
  methods
    
    function power = get.backlobe_attenuation(obj)
      power = obj.d_backlobe_attenuation;
    end
    
    function mode = get.angle_unit(obj)
      mode = obj.d_angle_unit;
    end
    
    function scale = get.scale(obj)
      scale = obj.d_scale;
    end
    
    function azimuth = get.azimuth(obj)
      azimuth = obj.d_azimuth;
    end
    
    function elevation = get.elevation(obj)
      elevation = obj.d_elevation;
    end
    
    function mainbeam_direction = get.mainbeam_direction(obj)
      mainbeam_direction = obj.d_mainbeam_direction;
    end
    
    function position = get.position(obj)
      position = obj.d_position;
    end
    
    function center_freq = get.center_freq(obj)
      center_freq = obj.d_center_freq;
    end
    
    function tx_power = get.tx_power(obj)
      tx_power = obj.d_tx_power;
    end
    
    function wavelength = get.wavelength(obj)
      wavelength = obj.d_wavelength;
    end
    
  end
  
  %% Public methods
  methods (Access = public)
        
    function gain = normPowerGain(obj,az,el)
      % Compute the power pattern gain for the given azimuth/elevations
      
      % If elevation isn't specified, assume zero
      if nargin == 2
        el = zeros(size(az));
      end
      
      % Calculate the gain in linear or dB
      if strncmpi(obj.scale,'Linear',1)
        gain = abs(obj.normVoltageGain(az,el)).^2;
      else
        gain = obj.normVoltageGain(az,el);
      end
      
    end
    
  end
  %% Private Methods
  methods (Access = private)
    
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
    
    % Convert all angle measures to degree
    function convertToDegree(obj)
      
      for ii = 1:numel(obj.angle_quantities)
        obj.(obj.angle_quantities{ii}) = (180/pi)*obj.(obj.angle_quantities{ii});
      end
      
    end
    
    % Convert all angle measures to radians
    function convertToRadian(obj)
      
      for ii = 1:numel(obj.angle_quantities)
        obj.(obj.angle_quantities{ii}) = (pi/180)*obj.(obj.angle_quantities{ii});
      end
      
    end
    
  end
  
  %% Hidden Methods (DO NOT EDIT THESE)
  methods (Hidden)
    
    % Sort the object properties alphabetically
    function value = properties( obj )
      
      % Put the properties list in sorted order
      propList = sort( builtin("properties", obj) );
      % Move any control switch parameters to the top of the output
      switches = {'scale','angle_unit'}';
      propList(ismember(propList,switches)) = [];
      propList = cat(1,switches,propList);
      if nargout == 0
        disp(propList);
      else
        value = propList;
      end
      
    end
    % Sort the object field names alphabetically
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
