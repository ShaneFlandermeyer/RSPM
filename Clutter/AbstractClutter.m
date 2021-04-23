% Abstract Class representing clutter
classdef (Abstract) AbstractClutter < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  % Constant properties
  properties (Constant = true,Access = protected)
    
    const = struct('Re',6370000,'ae',(4/3)*6370000);
    
  end
  
  properties (Access = private)
    angle_quantities = {'span_azimuth','span_azimuth_patch','az_center','az_center_patch'};
    voltage_quantities = {};
    power_quantities = {'gamma'};
  end
  
  properties (Dependent)
    angle_unit;
    scale;
    range;              % Distance of range ring from the radar
    earth_model;        % Earth model (currently only supports flat)
    span_azimuth;       % Azimuth span of the whole clutter ring
    span_azimuth_patch; % Azimuth span of individual clutter patches
    num_patches;        % Number of clutter patches in range ring
    az_center;          % Angle around which clutter patches are centered
    % Vector containing the azimuth of the center of each clutter patch in 
    % the range ring
    az_center_patch;
    
  end
  
  properties (Access = protected)
    d_angle_unit = 'Radians';
    d_scale = 'dB';
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
    
    function [Rc,Vc] = covariance(obj,radar)
      
      % Compute the clairvoyant clutter covariance matrix using eq. (64) of
      % the ward report, assuming zero velocity misalignment
      
      % Create copies of the inputs to avoid accidentally changing things
      clutter = copy(obj);
      radar = copy(radar);
      clutter.scale = 'Linear';
      clutter.angle_unit = 'Radians';
      radar.scale = 'Linear';
      
      % Clutter power distribution, assuming clutter is UNCORRELATED across
      % patches. This should really be squared by the square of the noise
      % power, but I'm normalizing it to get consistent results with the
      % ward report
      power_clutter = diag(radar.CNR(clutter));
      
      % Steering vector
      angle_graze = asin(radar.position(3)/clutter.range);
      eta = radar.antenna.spacing_element*cos(angle_graze)/radar.wavelength;
      beta = 2*norm(radar.velocity)*radar.pri/radar.antenna.spacing_element;
      
      % Spatial frequency
      freq_spatial = eta*sin(clutter.az_center_patch);
      % Normalized doppler shift (zero velocity misalignment)
      freq_dopp_norm = beta*eta*sin(clutter.az_center_patch + 0);
      
      N = radar.antenna.num_elements; % Number of array elements
      M = radar.num_pulses;           % Number of pulses per CPI
      Nc = clutter.num_patches;       % Number of clutter patches in ring
      a = zeros(N,Nc);                % Spatial steering vector
      b = zeros(M,Nc);                % Temporal steering vector
      Vc = zeros(M*N, Nc);            % Space-time steering vector
      % Compute the space-time steering vector
      % TODO: Perform this computation without loops using meshgrid
      for ii = 1:Nc
        a(:,ii) = exp(1i*2*pi*freq_spatial(ii)*(0:N-1));
        b(:,ii) = exp(1i*2*pi*freq_dopp_norm(ii)*(0:M-1));
        Vc(:,ii) = kron(b(:,ii),a(:,ii));
      end
      
      % Clutter covariance matrix
      Rc = Vc*power_clutter*Vc';
      
      
    end
    
  end
  
  %% Private Methods
  methods (Access = private)
    
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
    
    % Convert all angle measures to degree
    function convertToDegree(obj)
      
      for ii = 1:numel(obj.angle_quantities)
        obj.(obj.angle_quantities{ii}) = (180/pi)*obj.(obj.angle_quantities{ii});
      end
      
    end
    
    % Convert all angle measures to radians
    function convertToRadian(obj)
      
      for ii = 1:numel(obj.angle_quantities)
        obj.(obj.angle_quantities{ii}) = (pi/180)*obj.(obj.angle_quantities{ii});
      end
      
    end
    
  end
  
  %% Setter Methods
  methods
    
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
    
    function set.angle_unit(obj,val)
      
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Degrees',1) && ~strncmpi(obj.angle_unit,'Degrees',1)
        % Convert angle measures to degree
        obj.d_angle_unit = 'Degrees';
        obj.convertToDegree();
      elseif strncmpi(val,'Radians',1) && ~strncmpi(obj.angle_unit,'Radians',1)
        % Convert angle measures to radians
        obj.d_angle_unit = 'Radians';
        obj.convertToRadian();
      end
      
    end
    
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
    
    function out = get.angle_unit(obj)
      out = obj.d_angle_unit;
    end
    
    function out = get.scale(obj)
      out = obj.d_scale;
    end
    
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