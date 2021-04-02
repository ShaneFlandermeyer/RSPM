% A class representing a basic point target. 
%
% NOTE FOR PROJECT 2: This has not changed since project 1
%
% TODO: 
%  - Make this class abstract?
%
% Blame: Shane Flandermeyer
classdef Target < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  %% Properties
  % Target properties
  properties (Access = public)
    position = zeros(3,1);        % Target position in XYZ cartesian coordinates (m)
    velocity = zeros(3,1);        % Target velocity in XYZ cartesian coordinates (m/s)
    rcs = 0;                      % Target radar cross section (m^2)
  end % Public properties
  
  %% Setter methods
  methods
    
    function set.position(obj,val)
      % Should be a 3D vector
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      % If we're given a row vector, convert it to column
      if (isrow(val))
        val = val.';
      end
      obj.position = val;
    end
    
    function set.velocity(obj,val)
      % Should be a 3D vector
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      % If we're given a row vector, convert it to column
      if (isrow(val))
        val = val.';
      end
      obj.velocity = val;
    end
    
    function set.rcs(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.rcs = val;
    end
      
    
  end
  %% Getter methods
  methods

  end
  
  %% Hidden Methods
  methods (Hidden)
    % Sort the object properties alphabetically
    function value = properties( obj )
      propList = sort( builtin("properties", obj) );
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
