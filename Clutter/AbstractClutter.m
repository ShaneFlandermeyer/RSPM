% Abstract Class representing clutter
classdef (Abstract) AbstractClutter < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  % Constant properties
  properties (Constant = true,Access = protected)
    
    const = struct('Re',6370000,'ae',(4/3)*6370000);
    
  end
  
  properties (Dependent)
    
    range;
    earth_model;        % Earth model (currently only supports flat)
    span_azimuth;       % Azimuth span of the whole clutter ring
    span_azimuth_patch; % Azimuth span of individual clutter patches
    num_patches;        % Number of clutter patches in range ring
    az_center;
    az_center_patch;
    
  end
  
  properties (Access = protected)
    
    d_range;
    d_earth_model = 'Flat';
    d_span_azimuth;
    d_span_azimuth_patch;
    d_az_center = 0;
    d_az_center_patch;
    
  end
  
  %% Public Methods
  methods (Access = public)
    
    function area = patchArea(obj,radar)
      % Calculate the area of each clutter patch at a given range ring
      
      % AbstractClutter patch azimuth width
      width_az = 2*pi/obj.num_patches;
      % AbstractClutter patch range extent
      width_range = radar.range_resolution;
      % Grazing/elevation angle for the FLAT EARTH case
      angle_graze = asin(radar.position(3)/obj.range);
      % Area according to ward eq.(56)
      area = obj.range*width_az*width_range*sec(angle_graze);
      
    end
    
  end
  
  %% Setter Methods
  methods
    
    function set.az_center(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_az_center = val;
      obj.d_az_center_patch = (-(obj.span_azimuth/2-obj.span_azimuth_patch)+obj.az_center:...
        obj.span_azimuth_patch:...
        (obj.span_azimuth/2)+obj.az_center).';
      
    end
    
    function set.az_center_patch(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_az_center_patch = val;
      
    end
    
    function set.range(obj,val)
      
      obj.d_range = val;
      
    end
    
    function set.earth_model(obj,val)
      
      validateattributes(val,{'string','char'},{});
      obj.d_earth_model = val;
      
    end
        
    function set.span_azimuth(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_span_azimuth = val;
      obj.d_az_center_patch = (-(obj.span_azimuth/2-obj.span_azimuth_patch)+obj.az_center:...
        obj.span_azimuth_patch:...
        (obj.span_azimuth/2)+obj.az_center).';
      
    end
    
    function set.span_azimuth_patch(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_span_azimuth_patch = val;
      obj.d_az_center_patch = (-(obj.span_azimuth/2-obj.span_azimuth_patch)+obj.az_center:...
        obj.span_azimuth_patch:...
        (obj.span_azimuth/2)+obj.az_center).';
      
    end
  end
  
  %% Getter Methods
  methods
    
    function out = get.range(obj)
      out = obj.d_range;
    end
    
    function out = get.az_center(obj)
      out = obj.d_az_center;
    end
    
    function out = get.az_center_patch(obj)
      out = obj.d_az_center_patch;
    end
    
    function out = get.num_patches(obj)
      out = obj.d_span_azimuth/obj.d_span_azimuth_patch;
    end
    
    function out = get.earth_model(obj)
      out = obj.d_earth_model;
    end
    
    function out = get.span_azimuth(obj)
      out = obj.d_span_azimuth;
    end
    
    function out = get.span_azimuth_patch(obj)
      out = obj.d_span_azimuth_patch;
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