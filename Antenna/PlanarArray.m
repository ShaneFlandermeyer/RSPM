% Class Representation of a rectangular array aperture
%
% NOT USED FOR FINAL PROJECT. DOESN'T WORK AND ISN'T NEEDED RIGHT NOW!!!
% Blame: Shane Flandermeyer
%
% TODO:
%  - Add parameter for dB/linear scales
%  - Add parameter for angle unit
classdef PlanarArray < AntennaArray
  properties (Dependent)
    num_element_horiz; % Number of horizontal array elements
    num_element_vert;  % Number of vertical array elements
    element_pattern;   % Element beampattern
    gain_element;      % Element Gain
    %     elements;          % Element matrix
    spacing_element;
    angle_steering;
    gain_tx;
    gain_rx;
    gain_tx_array;
    gain_rx_array;
  end
  
  properties (Access = protected)
    d_num_element_horiz;
    d_num_element_vert;
    d_element_pattern;
    d_gain_element;
    %     d_elements;
    d_spacing_element;
    d_angle_steering;
    d_gain_tx;
    d_gain_rx;
    d_gain_tx_array;
    d_gain_rx_array;
  end
  
  %% Public Methods
  methods (Access = public)
    function AF = arrayFactor(obj,az,el)
      if nargin == 2
        el = zeros(size(az));
      end
      AF_horiz = zeros(size(az));
      AF_vert = zeros(size(el));
      for ii = 1:length(az)
        AF_horiz(ii) = sum(exp(1i*2*pi/obj.wavelength*obj.spacing_element*...
          (0:obj.num_element_horiz)*(cosd(az(ii))-cosd(obj.angle_steering))));
        AF_vert(ii) = sum(exp(1i*2*pi/obj.wavelength*obj.spacing_element*...
          (0:obj.num_element_vert)*(cosd(el(ii))-cosd(obj.angle_steering))));
      end
      AF = AF_horiz.*AF_vert;
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
    
    function set.num_element_horiz(obj,val)
      obj.d_num_element_horiz = val;
    end
    
    function set.num_element_vert(obj,val)
      obj.d_num_element_vert = val;
    end
    
    function set.element_pattern(obj,val)
      % TODO
      validateattributes(val,{'string','char'},{});
      obj.d_element_pattern = val;
      switch obj.d_element_pattern
        case 'Cosine'
          obj.elements = CosineAntennaElement(...
            [obj.num_element_horiz,obj.num_element_vert]);
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
    
    function out = get.num_element_horiz(obj)
      out = obj.d_num_element_horiz;
    end
    
    function out = get.num_element_vert(obj)
      out = obj.d_num_element_vert;
    end
    
    function out = get.element_pattern(obj)
      out = obj.d_element_pattern;
    end
    
    function out = get.gain_element(obj)
      out = obj.d_gain_element;
    end
    
  end
  
end