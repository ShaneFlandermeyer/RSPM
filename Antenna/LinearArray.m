% A class representing a linear antenna array

classdef LinearArray < AbstractAntennaArray
  
  properties (Dependent)
    num_elements; % Number of array elements
    element_pattern;    % Element beampattern
    gain_element;       % Element Gain
    spacing_element;    % Element spacing
    angle_steering;     % Steering angle
    gain_tx;            % Tx Gain
    gain_rx;            % Rx Gain
    mainbeam_direction; % Array mainbeam unit vector
    array_normal;       % Array normal direction unit vector
  end
  
  properties (Access = protected)
    d_num_elements;
    d_element_pattern = 'Cosine';
    d_gain_element;
    d_spacing_element;
    d_angle_steering = 0;
    d_gain_tx;
    d_gain_rx;
    d_mainbeam_direction = [1;0;0];
    d_array_normal = [1;0;0];
  end
  
  %% Constructors
  methods
    
    function obj = LinearArray()
      % Default Constructor
      
      % Add quantities that need to be converted when we change the scale
      % (linear <-> dB) or the angle unit (degree<->radian)
      obj.power_quantities = [obj.power_quantities];
      obj.voltage_quantities = [obj.voltage_quantities];
      obj.angle_quantities = [obj.angle_quantities;{'angle_steering'}];
    end
    
  end
  
  %% Public Methods
  methods (Access = public)
    function AF = arrayFactor(obj,angle)
      
      % Convert everything to radians before doing the calculation
      was_degrees = false;
      if strcmpi(obj.angle_unit,'Degrees')
        was_degrees = true;
        angle = (pi/180)*angle;
        obj.angle_unit = 'Radians';
      end
      
      % Calculate the array factor for each input angle
      AF = zeros(length(angle),1);
      for ii = 1:length(angle)
        AF(ii) = sum(exp(-1i*2*pi/obj.wavelength*obj.spacing_element*...
          (0:obj.num_elements-1)*(sin(angle(ii)) - sin(obj.angle_steering))));
      end
      
      % Convert back to degrees if necessary
      if was_degrees
        obj.angle_unit = 'Degrees';
      end
      
      % Convert to dB if necessary
      if strcmpi(obj.scale,'dB')
        AF = 10*log10(AF);
      end
      
    end
    
  end
  %% Setter Methods
  methods
    
    function set.array_normal(obj,val)
      validateattributes(val,{'numeric'},{'3d'})
      % Make it a column vector
      if isrow(val)
        val = val.';
      end
      obj.array_normal = val./norm(val);
    end
    
    function set.mainbeam_direction(obj,val)
      validateattributes(val,{'numeric'},{'3d'})
      % Make it a column vector
      if isrow(val)
        val = val.';
      end
      obj.d_mainbeam_direction = val./norm(val);
      obj.d_angle_steering = -atan2d(val(1)*obj.array_normal(2)-...
        obj.array_normal(1)*val(2),val(1)*val(2)+obj.array_normal(1)*obj.array_normal(2));
    end
    
    function set.gain_tx(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_gain_tx = val;
    end
    
    function set.gain_rx(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_gain_rx = val;
      
    end
    
    function set.angle_steering(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_angle_steering = val;
      if strcmpi(obj.angle_unit,'Radians')
        R = YPRMatrix(obj.d_angle_steering);
      else
        R = YPRMatrix(obj.d_angle_steering,[],[],'Degrees');
      end
      obj.d_mainbeam_direction = R*obj.array_normal;
      
    end
    
    function set.spacing_element(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_spacing_element = val;
      
    end
    
    function set.num_elements(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_num_elements = val;
      
    end
    
    function set.element_pattern(obj,val)
      
      validateattributes(val,{'string','char'},{});
      obj.d_element_pattern = val;
      switch obj.d_element_pattern
        case 'Cosine'
          obj.elements = CosineAntenna([obj.num_elements,1]);
        otherwise
          error('Element pattern not supported')
      end
      
    end
    
    function set.gain_element(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_gain_element = val;
      
    end
    
  end
  %% Getter Methods
  methods
    
    function out = get.array_normal(obj)
      out = obj.d_array_normal;
    end
    
    function out = get.mainbeam_direction(obj)
      out = obj.d_mainbeam_direction;
    end
    
    function out = get.gain_tx(obj)
      out = obj.d_gain_tx;
    end
    
    function out = get.gain_rx(obj)
      out = obj.d_gain_rx;
    end
    
    function out = get.angle_steering(obj)
      out = obj.d_angle_steering;
    end
    
    function out = get.spacing_element(obj)
      out = obj.d_spacing_element;
    end
    
    function out = get.num_elements(obj)
      out = obj.d_num_elements;
    end
    
    function out = get.element_pattern(obj)
      out = obj.d_element_pattern;
    end
    
    function out = get.gain_element(obj)
      out = obj.d_gain_element;
    end
    
  end
end