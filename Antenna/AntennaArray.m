% An abstract class representing an antenna array

classdef (Abstract) AntennaArray < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  properties (Access = private)
    power_quantities = {'gain_element','gain_tx','gain_rx'};
    voltage_quantities = {};
  end
  
  properties (Constant, Access = protected)
    const = struct('c',299792458)
  end
  
  properties (Dependent)
    angle_unit;
    scale;
    elements;
    center_freq;
    wavelength;
  end
  
  properties (Access = protected)
    d_angle_unit = 'Radian';
    d_scale = 'dB';
    d_elements;
    d_center_freq;
    d_wavelength;
  end
  %% Setter Methods
  
  methods 
    
    function set.angle_unit(obj,val)
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Degree',1)
        % Convert angle measures to degree
        obj.d_angle_unit = 'Degree';
%         obj.convertToDegree();
      elseif strncmpi(val,'Radian',1)
        % Convert angle measures to radians
        obj.d_angle_unit = 'Radian';
%         obj.convertToRadian();
      end
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
    
    function set.elements(obj,val)
      obj.d_elements = val;
    end
    
    function set.center_freq(obj,val)
      obj.d_center_freq = val;
      obj.d_wavelength = obj.const.c/val;
    end
    
    function set.wavelength(obj,val)
      obj.d_wavelength = val;
      obj.d_center_freq = obj.const.c/obj.wavelength;
    end
    
  end
  
  %% Getter Methods
  methods
    
    function out = get.angle_unit(obj)
      out = obj.d_angle_unit;
    end
    
    function out = get.scale(obj)
      out = obj.d_scale;
    end
    
    function out = get.elements(obj)
      out = obj.d_elements;
    end
    
    function out = get.center_freq(obj)
      out = obj.d_center_freq;
    end
    
    function out = get.wavelength(obj)
      out = obj.d_wavelength;
    end
    
  end
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
  %% Hidden Methods
  methods (Hidden)
    % Sort the object properties alphabetically
    function value = properties( obj )
      % Put the properties list in sorted order
      propList = sort( builtin("properties", obj) );
      % Move any control switch parameters to the top of the output
      switches = {'angle_unit','element_pattern','scale'}';
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
  
end