% An abstract class representing an antenna array

classdef (Abstract) AntennaArray < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
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
  
end