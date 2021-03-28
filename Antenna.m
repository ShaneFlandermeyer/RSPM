% A class representing an antenna. 
%
% TODO: Make this an abstract class and implement subclasses for different
% types of antennas.

classdef Antenna < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  %% Properties
  
  % Constants
  properties (Constant = true, Access = private)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  
  % Private properties
  properties (Access = private)
    initial_param; % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
    % A list of antenna parameters that are angles, used when switching
    % between radian mode and degree mode
    angle_params = {'azimuth','elevation'};
    power_quantities = {};
    voltage_quantities = {};
  end
  
  % Antenna Properties
  properties (Access = public)
    angle_unit = 'Radian';
    scale = 'dB';
    width = 0; % Width of the antenna aperture
    height = 0; % Height of the antenna aperture
    azimuth = 0; % Azimuth angle of the antenna aperture w.r.t the x axis
    elevation = 0; % Elevation angle of the antenna aperture
    mainbeam_direction = [1;0;0]; % Cartesian (XYZ) antenna beam unit vector
    position = [0;0;0]; % Cartesian (XYZ) antenna position
    center_freq;       % Center frequency
    tx_power;          % Tx power
    wavelength;        % Carrier wavelength
  end % Public properties
  
  % Dependent properties that are set based on the antenna properties
  properties (Dependent)
    area;
    beamwidth_azimuth_3db;
    beamwidth_elevation_3db;
    power_gain;
  end % Dependent Properties
  
  %% Setter methods
  methods
    
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
    end
    function set.width(obj,val)
      validateattributes(val,{'numeric'},{'positive'});
      obj.width = val;
    end
    
    function set.height(obj,val)
      validateattributes(val,{'numeric'},{'positive'});
      obj.height = val;
    end
    
    function set.azimuth(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.azimuth = val;
    end
    
    function set.elevation(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.elevation = val;
    end
    
    function set.mainbeam_direction(obj,val)
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      if isrow(val) % Make this a column vector
        val = val.';
      end
      val = val ./ norm(val); % Normalize to unit vector
      obj.mainbeam_direction = val; % Set object property
      obj.checkIfUpdated('mainbeam_direction',val); % Update dependent properties
    end
    
    function set.angle_unit(obj,val)
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Degree',1)
        % Convert angle measures to degree
        obj.angle_unit = 'Degree';
        obj.convertToDegree();
      elseif strncmpi(val,'Radian',1)
        % Convert angle measures to radians
        obj.angle_unit = 'Radian';
        obj.convertToRadian();
      end
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
    
    function set.center_freq(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.center_freq = val;
      obj.checkIfUpdated('center_freq',val);
    end
  end
  
  %% Getter methods
  methods
    
    % Calculate the true area of the aperture
    function A = get.area(obj)
      A = obj.width*obj.height;
    end
    
    % Calculate the 3dB beamwidth for our power pattern in azimuth
    % ASSUMPTION: Sinc pattern
    function beamwidth = get.beamwidth_azimuth_3db(obj)
      beamwidth = 0.89*obj.wavelength/obj.width;
      if (strncmpi(obj.angle_unit,'Degree',1))
        beamwidth = (180/pi)*beamwidth;
      end
    end
    
    % Calculate the 3dB beamwidth for our power pattern in elevation
    % ASSUMPTION: Sinc pattern
    function beamwidth = get.beamwidth_elevation_3db(obj)
      beamwidth = 0.89*obj.wavelength/obj.height;
      if (strncmpi(obj.angle_unit,'Degree',1))
        beamwidth = (180/pi)*beamwidth;
      end
    end
    
    % Get the maximum power gain for the aperture from the 3db beamwidths
    % ASSUMPTION: Rectangular aperture
    function G = get.power_gain(obj)
      if strncmpi(obj.angle_unit,'Degree',1)
        G = 26e3/(obj.beamwidth_azimuth_3db*obj.beamwidth_elevation_3db);
      else
        G = 7.9/(obj.beamwidth_azimuth_3db*obj.beamwidth_elevation_3db);
      end
      % Convert to dB if necessary
      if (strncmpi(obj.scale,'db',1))
        G = 10*log10(G);
      end
    end
    
  end
  %% Public Methods
  methods (Access = public)
    
    % Calculate the normalized antenna pattern gain for a given
    % azimuth/elevation
    % ASSUMPTION: Rectangular Aperture
    function gain = getNormPatternGain(obj,az,el)
      if strncmpi(obj.angle_unit,'Radian',1)
        % Get the separable azimuth component
        P_az = sinc(obj.width/obj.wavelength*sin(az));
        % Get the separable elevation component
        P_el = sinc(obj.height/obj.wavelength*sin(el));
      else 
        % Same calculations as above, but with az/el in degrees
        P_az = sinc(obj.width/obj.wavelength*sind(az));
        P_el = sinc(obj.height/obj.wavelength*sind(el));
      end
      % Get the composite pattern gain
      gain = P_az.*P_el;
    end
  end % Methods
  
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
      for ii = 1:numel(obj.angle_params)
        obj.(obj.angle_params{ii}) = (180/pi)*obj.(obj.angle_params{ii});
      end
    end
    
    % Convert all angle measures to radians
    function convertToRadian(obj)
      for ii = 1:numel(obj.angle_params)
        obj.(obj.angle_params{ii}) = (pi/180)*obj.(obj.angle_params{ii});
      end
    end
    
    % A helper functions to update dependent parameters that can't be
    % marked explicitly dependent. For example, the azimuth/elevation angle
    % of the mainbeam should be able to update the mainbeam unit vector and
    % vice-versa, so neither can be made explicitly dependent
    function updateParams(obj, param_name, param_val)
      % No parameter value given. Exit immediately to avoid breaking things
      if isempty(param_val)
        return
      end
      
      
      switch (param_name)
        
        % Mainbeam direction updated
        % Update list
        % -------------------------
        % 1. Azimuth and Elevation angles
        case 'mainbeam_direction'
          [obj.azimuth,obj.elevation] = ...
            cart2sph(obj.mainbeam_direction(1),obj.mainbeam_direction(2),obj.mainbeam_direction(3));
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
    
    % Check if the given parameter has already been updated in a recursive
    % updateParams call. If it hasn't, add it to the list and update it
    function checkIfUpdated(obj, param_name, param_val)
      if ~any(strcmp(param_name, obj.updated_list))
        if isempty(obj.updated_list)
          obj.initial_param = param_name;
        end
        obj.updated_list{end+1} = param_name;
        obj.updateParams(param_name, param_val);
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
