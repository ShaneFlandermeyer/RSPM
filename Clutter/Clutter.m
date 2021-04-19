% Abstract Class representing clutter
classdef (Abstract) Clutter < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  % Constant properties
  properties (Constant = true,Access = protected)
    
    const = struct('Re',6370000,'ae',(4/3)*6370000);
    
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