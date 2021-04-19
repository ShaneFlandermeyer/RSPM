% A class representing a linear antenna array

classdef LinearArray < AntennaArray
  properties (Dependent)
    num_element; % Number of array elements
    element_pattern;   % Element beampattern
    gain_element;      % Element Gain
    spacing_element;   % Element spacing
    angle_steering;    % Steering angle
    gain_tx;           % Tx Gain
    gain_rx;           % Rx Gain
    mainbeam_direction;
    array_normal;
  end
  
  properties (Access = protected)
    d_num_element;
    d_element_pattern = 'Cosine';
    d_gain_element;
    d_spacing_element;
    d_angle_steering;
    d_gain_tx;
    d_gain_rx;
    d_mainbeam_direction;
    d_array_normal = [1;0;0];
  end
  
  %% Public Methods
  methods (Access = public)
    function AF = arrayFactor(obj,angle)
      AF = zeros(length(angle),1);
      if strcmpi(obj.angle_unit,'Radian')
        for ii = 1:length(angle)
          AF(ii) = sum(exp(-1i*2*pi/obj.wavelength*obj.spacing_element*...
            (0:obj.num_element-1)*(sin(angle(ii)) - sin(obj.angle_steering))));
        end
      else
        for ii = 1:length(angle)
          AF(ii) = sum(exp(-1i*2*pi/obj.wavelength*obj.spacing_element*...
            (0:obj.num_element-1)*(sin(angle(ii)) - sin(obj.angle_steering))));
        end
      end
      if strcmpi(obj.scale,'dB')
        AF = 10*log10(AF);
      end
    end
  end
  %% Setter Methods
  methods
    
    function set.array_normal(obj,val)
      obj.array_normal = val;
    end
    
    function set.mainbeam_direction(obj,val)
      obj.d_mainbeam_direction = val;
      obj.d_angle_steering = -atan2d(val(1)*obj.array_normal(2)-...
        obj.array_normal(1)*val(2),val(1)*val(2)+obj.array_normal(1)*obj.array_normal(2));
    end
    
    function set.gain_tx(obj,val)
      obj.d_gain_tx = val;
    end
    
    function set.gain_rx(obj,val)
      obj.d_gain_rx = val;
    end
    
    function set.angle_steering(obj,val)
      obj.d_angle_steering = val;
      R = [cosd(val) -sind(val) 0;
           sind(val)  cos(val)  0;
               0         0      1];
      obj.d_mainbeam_direction = R*obj.array_normal;
    end
    
    function set.spacing_element(obj,val)
      obj.d_spacing_element = val;
    end
    
    function set.num_element(obj,val)
      obj.d_num_element = val;
    end
    
    function set.element_pattern(obj,val)
      validateattributes(val,{'string','char'},{});
      obj.d_element_pattern = val;
      switch obj.d_element_pattern
        case 'Cosine'
          obj.elements = CosineAntenna([obj.num_element,1]);
      end
    end
    
    function set.gain_element(obj,val)
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
    
    function out = get.num_element(obj)
      out = obj.d_num_element;
    end
    
    function out = get.element_pattern(obj)
      out = obj.d_element_pattern;
    end
    
    function out = get.gain_element(obj)
      out = obj.d_gain_element;
    end
    
  end
end