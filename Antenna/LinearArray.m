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
    gain_tx_array;     % Full array Tx gain
    gain_rx_array;     % Full array Rx gain
  end
  
  properties (Access = protected)
    d_num_element;
    d_element_pattern;
    d_gain_element;
    d_spacing_element;
    d_angle_steering;
    d_gain_tx;
    d_gain_rx;
    d_gain_tx_array;
    d_gain_rx_array;
  end
  
  %% Public Methods
  methods (Access = public)
    function AF = arrayFactor(obj,angle)
      % Compute the array factor for the 
      AF = zeros(length(angle),1);
      for ii = 1:length(angle)
        AF(ii) = sum(exp(-1i*2*pi/obj.wavelength*obj.spacing_element*...
          (0:obj.num_element-1)*(sind(angle(ii)) - sind(obj.angle_steering))));
      end
    end
  end
  %% Setter Methods
  methods
    
    function set.gain_tx_array(obj,val)
      obj.d_gain_tx_array = val;
    end
    
    function set.gain_rx_array(obj,val)
      obj.d_gain_rx_array = val;
    end
    
    function set.gain_tx(obj,val)
      obj.d_gain_tx = val;
    end
    
    function set.gain_rx(obj,val)
      obj.d_gain_rx = val;
    end
    
    function set.angle_steering(obj,val)
      obj.d_angle_steering = val;
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
          obj.elements = CosineAntennaElement(...
            [obj.num_element,1]);
      end
    end
    
    function set.gain_element(obj,val)
      obj.d_gain_element = val;
    end
    
  end
  %% Getter Methods
  methods
    
    function out = get.gain_tx_array(obj)
      out = obj.d_gain_tx_array;
    end
    
    function out = get.gain_rx_array(obj)
      out = obj.d_gain_rx_array;
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