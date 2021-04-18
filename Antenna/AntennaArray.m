% An abstract class representing an antenna array

classdef (Abstract) AntennaArray < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  properties (Constant, Access = protected)
    const = struct('c',299792458)
  end
  properties (Dependent)
    elements;
    center_freq;
    wavelength;
  end
  
  properties (Access = protected)
    d_elements;
    d_center_freq;
    d_wavelength;
  end
  %% Setter Methods
  
  methods 
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
  
  %% Hidden Methods
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
  
end