classdef Target < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  %% Properties
  % Private properties
  properties (Access = private)
    initial_param; % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
  end
  % Target properties
  properties (Access = public)
    position = zeros(3,1);        % Target position in XYZ cartesian coordinates (m)
    velocity = zeros(3,1);        % Target velocity in XYZ cartesian coordinates (m/s)
    reference_position = zeros(3,1); % The reference point from which the 
                                  %  range is calculates
    rcs = 0;                      % Target radar cross section (m^2)
  end % Public properties
  % Dependent properties
  properties (Dependent)
    range;    % Target absolute range (m)
  end % Dependent Properties
  
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
    
    function val = get.range(obj)
      val = norm(obj.position-obj.reference_position);
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