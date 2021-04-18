classdef RectangularArray < AntennaArray
  properties (Dependent)
    num_element_horiz; % Number of horizontal array elements
    num_element_vert;  % Number of vertical array elements
    element_pattern;   % Element beampattern
    gain_element;      % Element Gain
    elements;          % Element matrix
    spacing_element;
  end
  
  properties (Access = protected)
    d_num_element_horiz;
    d_num_element_vert;
    d_element_pattern;
    d_gain_element;
    d_elements;
    d_spacing_element;
  end
  
  %% Setter Methods
  methods
    
    function set.spacing_element(obj,val)
      obj.d_spacing_element = val;
    end
    
    function set.elements(obj,val)
      obj.d_elements = val;
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
    
    function out = get.spacing_element(obj)
      out = obj.d_spacing_element;
    end
    
    function out = get.elements(obj)
      out = obj.d_elements;
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