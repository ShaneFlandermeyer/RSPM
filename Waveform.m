% An abstract class representing a waveform 

classdef  (Abstract) Waveform < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  %% Public properties
  properties (Access = public)
    samp_rate; % ADC sample rate
    normalization = 'Energy';
  end
  
  properties (Abstract)
    bandwidth; % Waveform bandwidth
  end
  %% Dependent properties
  properties (Dependent,Access = public)
    data; % Data vector for a waveform with the given parameters
  end
  
  %% Getters and setters
  methods
    function set.normalization(obj,val)
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Time-Bandwidth',1) 
        obj.normalization = 'Time-Bandwidth';
      elseif strncmpi(val,'Energy',1) 
        obj.normalization = 'Energy';
      elseif strncmpi(val,'None',1)
        obj.normalization = 'None';
      else
        error('Unknown normalization type')
      end
    end
    function data = get.data(obj)
      data = waveform(obj);
    end
  end
  %% Abstract Methods
  methods (Abstract)
    [ambfun,t,fd] = ambiguityFunction(obj);
    data = waveform(obj);
  end
  
  
  %% Hidden Methods (DO NOT EDIT THESE)
  
  % Sorts the object properties alphabetically
  methods (Access = protected,Hidden)
    
    function value = properties( obj )
      % Put the properties list in sorted order
      propList = sort( builtin("properties", obj) );
      % Move any control switch parameters to the top of the output
      switches = {'normalization','scale', 'const'}';
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
  
end