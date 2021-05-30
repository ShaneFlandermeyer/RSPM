% A class representing a basic point target.
%
% Blame: Shane Flandermeyer
classdef (Abstract) AbstractTarget < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  properties (Dependent)
    
    position;       % Target position in XYZ cartesian coordinates (m)
    velocity;      % Target velocity in XYZ cartesian coordinates (m/s)
    rcs;            % Target radar cross section (m^2)
    azimuth;
    elevation;
    
  end
  
  properties (Access = protected)
    
    d_position;
    d_velocity;
    d_rcs;
    d_azimuth;
    d_elevation;
    
  end
  
  %% Public Methods
  methods (Access = public)

    
  end
  %% Setter methods
  methods
    
    function set.azimuth(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_azimuth = val;
    end
    
    function set.elevation(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan'});
      obj.d_elevation = val;
    end
    
    function set.position(obj,val)
      % Should be a 3D vector
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      % If we're given a row vector, convert it to column
      if (isrow(val))
        val = val.';
      end
      obj.d_position = val;
    end
    
    function set.velocity(obj,val)
      % Should be a 3D vector
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      % If we're given a row vector, convert it to column
      if (isrow(val))
        val = val.';
      end
      obj.d_velocity = val;
    end
    
    function set.rcs(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_rcs = val;
    end
    
    
  end
  
  %% Getter methods
  methods
    
    function out = get.azimuth(obj)
      out = obj.d_azimuth;
    end
    
    function out = get.elevation(obj)
      out = obj.d_elevation;
    end
    
    function out = get.position(obj)
      out = obj.d_position;
    end
    
    function out = get.velocity(obj)
      out = obj.d_velocity;
    end
    
    function out = get.rcs(obj)
      out = obj.d_rcs;
    end
    
    
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
