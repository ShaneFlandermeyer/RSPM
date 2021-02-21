% A class representing an antenna. For now, represents a single aperture
% with a given width, height, and mainbeam pointing vector

classdef Antenna < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  %% Properties
  
  % Private properties
  properties (Access = private)
    initial_param; % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
    % A list of antenna parameters that are angles, used when switching
    % between radian mode and degree mode
    angle_params = {'azimuth','elevation'};
  end
  
  % Antenna Properties
  properties (Access = public)
    angle_mode = 'Radian';
    width = 0; % Width of the antenna aperture
    height = 0; % Height of the antenna aperture
    azimuth = 0; % Azimuth angle of the antenna aperture w.r.t the x axis
    elevation = 0; % Elevation angle of the antenna aperture
    position = [1;0;0]; % Cartesian (XYZ) antenna beam unit vector
  end % Public properties
  
  % Dependent properties that are set based on the antenna properties
  properties (Dependent)
    area;
  end % Dependent Properties
  
  %% Setter methods
  methods
    
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
    
    function set.position(obj,val)
      validateattributes(val,{'numeric'},...
        {'vector','3d','finite','nonnan'});
      if isrow(val) % Make this a column vector
        val = val.';
      end
      val = val ./ norm(val); % Normalize to unit vector
      obj.position = val; % Set object property
      obj.checkIfUpdated('position',val); % Update dependent properties
    end
    
    function set.angle_mode(obj,val)
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Degree',1)
        % Convert angle measures to degree
        obj.angle_mode = 'Degree';
        obj.convertToDegree();
      elseif strncmpi(val,'Radian',1)
        % Convert angle measures to radians
        obj.angle_mode = 'Radian';
        obj.convertToRadian();
      end
    end
      
  end
  %% Getter methods
  methods
    
    % Calculate the true area of the aperture
    function val = get.area(obj)
      val = obj.width*obj.height;
    end
    
  end
  
  %% Private Methods
  methods (Access = private)
    
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
        case 'position'
          [obj.azimuth,obj.elevation] = ...
            cart2sph(obj.position(1),obj.position(2),obj.position(3));
          
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
        obj.updated_list{end+1} = param_name;
        obj.updateParams(param_name, param_val);
      end
    end
    
  end
  %% Hidden Methods (DO NOT EDIT THESE)
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