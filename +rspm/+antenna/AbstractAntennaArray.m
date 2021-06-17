% An abstract class representing an antenna array

classdef (Abstract) AbstractAntennaArray < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  % Conversion quantities
  properties (Access = protected)
    
    powerQuantities = {'elementGain','txGain','rxGain'};
    voltageQuantities = {};
    angleQuantities = {};
  end
  
  % Constants
  properties (Constant, Access = protected)
    const = struct('c',299792458)
  end
  
  % Public properties
  properties (Dependent)
    nElements; % Number of array elements
    angleUnit;
    scale;
    elements;
    centerFreq;
    wavelength;
  end
  
  % Internal data storage
  properties (Access = protected)
    d_nElements;
    d_angleUnit = 'Radians';
    d_scale = 'dB';
    d_elements;
    d_centerFreq;
    d_wavelength;
  end
  
  %% Public Methods
  
  methods
    
    function set.nElements(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_nElements = val;
      
    end
    
    function a = spatialSteeringVector(obj,freq_spatial)
      % Computes the spatial steering vector to a given spatial frequency
      % If the input is a vector of size L, this function returns an N x L
      % matrix, where N is the number of array elements and each column in 
      % the matrix corresponds to a spatial frequency from the input
      
      % If the input is a column vector, make it a row vector to maintain
      % the output dimensions specified above
      if iscolumn(freq_spatial)
        freq_spatial = freq_spatial.';
      end

      if numel(freq_spatial) == 1 % Scalar case
        a = exp(1i*2*pi*freq_spatial*(0:obj.nElements-1)');
      else % Vector case
        % Set up problem dimensions so that we can use a Hadamard product
        % instead of a loop
        N = repmat((0:obj.nElements-1)',1,numel(freq_spatial));
        freq_spatial = repmat(freq_spatial,obj.nElements,1);
        a = exp(1i*2*pi*freq_spatial.*N);
      end

    end
    
  end
  
  %% Setter Methods
  
  methods
    
    function out = get.nElements(obj)
      
      out = obj.d_nElements;
      
    end
    
    function set.angleUnit(obj,val)
      
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Degrees',1) && ~strncmpi(obj.angleUnit,'Degrees',1)
        % Convert angle measures to degree
        obj.d_angleUnit = 'Degrees';
        obj.convertToDegree();
        % Also update the individual element objects
        [obj.elements.angleUnit] = deal('Degrees');
      elseif strncmpi(val,'Radians',1)&& ~strncmpi(obj.angleUnit,'Radians',1)
        % Convert angle measures to radians
        obj.d_angleUnit = 'Radians';
        obj.convertToRadian();
        [obj.elements.angleUnit] = deal('Radians');
      end
      
    end
    
    function set.scale(obj,val)
      
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Linear',1) && ~strncmpi(obj.scale,'Linear',1)
        % Change all voltage/power quantities to linear scale
        obj.d_scale = 'Linear';
        obj.convertToLinear();
        % Also update the individual element objects
        [obj.elements.scale] = deal('Linear');
        
      elseif strncmpi(val,'db',1) && ~strncmpi(obj.scale,'dB',1)
        % Change all voltage/power quantities to dB scale
        obj.convertTodB();
        obj.d_scale = 'dB';
        % Also update the individual element objects
        [obj.elements.scale] = deal('dB');
      end
      
    end
    
    function set.elements(obj,val)
      
      validateattributes(val, {'AbstractAntenna'}, {})
      obj.d_elements = val;
      
    end
    
    function set.centerFreq(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_centerFreq = val;
      obj.d_wavelength = obj.const.c/val;
      
    end
    
    function set.wavelength(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_wavelength = val;
      obj.d_centerFreq = obj.const.c/val;
      
    end
    
  end
  
  %% Getter Methods
  methods
    
    function out = get.angleUnit(obj)
      out = obj.d_angleUnit;
    end
    
    function out = get.scale(obj)
      out = obj.d_scale;
    end
    
    function out = get.elements(obj)
      out = obj.d_elements;
    end
    
    function out = get.centerFreq(obj)
      out = obj.d_centerFreq;
    end
    
    function out = get.wavelength(obj)
      out = obj.d_wavelength;
    end
    
  end
  %% Private Methods
  methods
    
    % Convert all parameters that are currently in linear units to dB
    function convertTodB(obj)
      
      for ii = 1:numel(obj.powerQuantities)
        obj.(obj.powerQuantities{ii}) = 10*log10(obj.(obj.powerQuantities{ii}));
      end
      
      for ii = 1:numel(obj.voltageQuantities)
        obj.(obj.voltageQuantities{ii}) = 20*log10(obj.(obj.voltageQuantities{ii}));
      end
      
    end
    
    % Convert all parameters that are currently in dB to linear units
    function convertToLinear(obj)
      
      for ii = 1:numel(obj.powerQuantities)
        obj.(obj.powerQuantities{ii}) = 10^(obj.(obj.powerQuantities{ii})/10);
      end
      
      for ii = 1:numel(obj.voltageQuantities)
        obj.(obj.voltageQuantities{ii}) = 10^(obj.(obj.voltageQuantities{ii})/20);
      end
      
    end
    
    % Convert all angle measures to degree
    function convertToDegree(obj)
      
      for ii = 1:numel(obj.angleQuantities)
        obj.(obj.angleQuantities{ii}) = (180/pi)*obj.(obj.angleQuantities{ii});
      end
      
    end
    
    % Convert all angle measures to radians
    function convertToRadian(obj)
      
      for ii = 1:numel(obj.angleQuantities)
        obj.(obj.angleQuantities{ii}) = (pi/180)*obj.(obj.angleQuantities{ii});
      end
      
    end
    
  end % Private methods
  %% Hidden Methods
  methods (Hidden)
    
    % Sort the object properties alphabetically
    function value = properties( obj )
      
      % Put the properties list in sorted order
      propList = sort( builtin("properties", obj) );
      % Move any control switch parameters to the top of the output
      switches = {'angleUnit','elementPattern','scale'}';
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