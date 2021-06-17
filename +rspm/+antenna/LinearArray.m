% A class representing a linear antenna array

classdef LinearArray < rspm.antenna.AbstractAntennaArray
  
  properties (Dependent)
    
    elementPattern;    % Element beampattern
    elementGain;       % Element Gain
    elementSpacing;    % Element spacing
    steeringAngle;     % Steering angle
    txGain;            % Tx Gain
    rxGain;            % Rx Gain
    mainbeamDirection; % Array mainbeam unit vector
    arrayNormal;       % Array normal direction unit vector
  end
  
  properties (Access = protected)
    
    d_elementPattern = 'Cosine';
    d_elementGain;
    d_elementSpacing;
    d_steeringAngle = 0;
    d_txGain;
    d_rxGain;
    d_mainbeamDirection = [1;0;0];
    d_arrayNormal = [1;0;0];
  end
  
  %% Constructors
  methods
    
    function obj = LinearArray()
      % Default Constructor
      
      % Add quantities that need to be converted when we change the scale
      % (linear <-> dB) or the angle unit (degree<->radian)
      obj.powerQuantities = [obj.powerQuantities];
      obj.voltageQuantities = [obj.voltageQuantities];
      obj.angleQuantities = [obj.angleQuantities;{'steeringAngle'}];
    end
    
  end
  
  %% Public Methods
  methods (Access = public)
    function AF = arrayFactor(obj,angle)
      
      % Convert everything to radians before doing the calculation
      was_degrees = false;
      if strcmpi(obj.angleUnit,'Degrees')
        was_degrees = true;
        angle = (pi/180)*angle;
        obj.angleUnit = 'Radians';
      end
      
      % Calculate the array factor for each input angle
      AF = zeros(length(angle),1);
      for ii = 1:length(angle)
        AF(ii) = sum(exp(-1i*2*pi/obj.wavelength*obj.elementSpacing*...
          (0:obj.nElements-1)*(sin(angle(ii)) - sin(obj.steeringAngle))));
      end
      
      % Convert back to degrees if necessary
      if was_degrees
        obj.angleUnit = 'Degrees';
      end
      
      % Convert to dB if necessary
      if strcmpi(obj.scale,'dB')
        AF = 10*log10(AF);
      end
      
    end
    
  end
  %% Setter Methods
  methods
    
    function set.arrayNormal(obj,val)
      validateattributes(val,{'numeric'},{'3d'})
      % Make it a column vector
      if isrow(val)
        val = val.';
      end
      obj.arrayNormal = val./norm(val);
    end
    
    function set.mainbeamDirection(obj,val)
      validateattributes(val,{'numeric'},{'3d'})
      % Make it a column vector
      if isrow(val)
        val = val.';
      end
      obj.d_mainbeamDirection = val./norm(val);
      obj.d_steeringAngle = -atan2d(val(1)*obj.arrayNormal(2)-...
        obj.arrayNormal(1)*val(2),val(1)*val(2)+obj.arrayNormal(1)*obj.arrayNormal(2));
    end
    
    function set.txGain(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_txGain = val;
    end
    
    function set.rxGain(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_rxGain = val;
      
    end
    
    function set.steeringAngle(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_steeringAngle = val;
      if strcmpi(obj.angleUnit,'Radians')
        R = YPRMatrix(obj.d_steeringAngle);
      else
        R = YPRMatrix(obj.d_steeringAngle,[],[],'Degrees');
      end
      obj.d_mainbeamDirection = R*obj.arrayNormal;
      
    end
    
    function set.elementSpacing(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_elementSpacing = val;
      
    end
    
    
    function set.elementPattern(obj,val)
      
      validateattributes(val,{'string','char'},{});
      obj.d_elementPattern = val;
      switch obj.d_elementPattern
        case 'Cosine'
          obj.elements = CosineAntenna([obj.nElements,1]);
        otherwise
          error('Element pattern not supported')
      end
      
    end
    
    function set.elementGain(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_elementGain = val;
      
    end
    
  end
  %% Getter Methods
  methods
    
    function out = get.arrayNormal(obj)
      out = obj.d_arrayNormal;
    end
    
    function out = get.mainbeamDirection(obj)
      out = obj.d_mainbeamDirection;
    end
    
    function out = get.txGain(obj)
      out = obj.d_txGain;
    end
    
    function out = get.rxGain(obj)
      out = obj.d_rxGain;
    end
    
    function out = get.steeringAngle(obj)
      out = obj.d_steeringAngle;
    end
    
    function out = get.elementSpacing(obj)
      out = obj.d_elementSpacing;
    end
    
    
    function out = get.elementPattern(obj)
      out = obj.d_elementPattern;
    end
    
    function out = get.elementGain(obj)
      out = obj.d_elementGain;
    end
    
  end
end