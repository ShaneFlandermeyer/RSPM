% Abstract Class representing clutter
classdef (Abstract) AbstractClutter < matlab.mixin.Copyable & matlab.mixin.CustomDisplay
  
  % Constant properties
  properties (Constant = true,Access = protected)
    
    const = struct('Re',6370000,'ae',(4/3)*6370000);
    
  end
  
  properties (Access = private)
    angleQuantities = {'azimuthSpan','azimuthSpanPatch','azimuthCenter','azimuthCenterPatch'};
    voltageQuantities = {};
    powerQuantities = {'gamma'};
  end
  
  properties (Dependent)
    angleUnit;
    scale;
    range;              % Distance of range ring from the radar
    earthModel;        % Earth model (currently only supports flat)
    azimuthSpan;       % Azimuth span of the whole clutter ring
    azimuthSpanPatch; % Azimuth span of individual clutter patches
    nPatches;        % Number of clutter patches in range ring
    azimuthCenter;          % Angle around which clutter patches are centered
    % Vector containing the azimuth of the center of each clutter patch in 
    % the range ring
    azimuthCenterPatch;
    
  end
  
  properties (Access = protected)
    d_angleUnit = 'Radians';
    d_scale = 'dB';
    d_range;
    d_earthModel = 'Flat';
    d_azimuthSpan;
    d_azimuthSpanPatch;
    d_azimuthCenter = 0;
    d_azimuthCenterPatch;
    
  end
  
  %% Abstract Methods
  methods (Abstract)
    % Calculate the clutter patch RCS observed by the given radar system
    sigma = patchRCS(obj,radar);
  end
  
  %% Public Methods
  methods (Access = public)
    
    function cnr = CNR(obj,radar)
      % Calculates the clutter-to-noise ratio for the given clutter at the
      % given range and angles
      
      % TODO: Only supports array objects for now
      if (~isa(radar.antenna,'AbstractAntennaArray'))
        error('Antenna must be an array (for now)')
      end
      
      % Create a copy of the current object and change everything to
      % linear/radians
      radar = copy(radar);
      radar.scale = 'Linear';
      radar.antenna.angleUnit = 'Radians';
      
      clutter = copy(obj);
      clutter.scale = 'Linear';
      clutter.angleUnit = 'Radians';
      
      % Array factor
      AF = radar.antenna.arrayFactor(clutter.azimuthCenterPatch);
      % Full array transmit gain
      Gt = radar.antenna.txGain*(abs(AF).^2).*...
        radar.antenna.elements(1,1).normPowerGain(clutter.azimuthCenterPatch);
      % Fuull array receive gain
      g = radar.antenna.elementGain*radar.antenna.rxGain*...
        radar.antenna.elements(1,1).normPowerGain(clutter.azimuthCenterPatch);
      % AbstractClutter RCS
      sigma = clutter.patchRCS(radar);
      
      % CNR 
      cnr = radar.txPower*Gt.*g*radar.wavelength^2*sigma/((4*pi)^3*...
        radar.noisePower*radar.systemLoss*clutter.range^4);
      
      % Convert to dB if necessary
      if strcmpi(obj.scale,'dB')
        cnr = 10*log10(cnr);
      end
      
    end
    
    function area = patchArea(obj,radar)
      % Calculate the area of each clutter patch at a given range ring
      
      % AbstractClutter patch azimuth width
      width_az = 2*pi/obj.nPatches;
      % AbstractClutter patch range extent
      width_range = radar.rangeResolution;
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
      clutter.angleUnit = 'Radians';
      radar.scale = 'Linear';
      
      % Clutter power distribution, assuming clutter is UNCORRELATED across
      % patches. This should really be squared by the square of the noise
      % power, but I'm normalizing it to get consistent results with the
      % ward report
      power_clutter = radar.noisePower*diag(clutter.CNR(radar));
      
      % Steering vector
      angle_graze = asin(radar.position(3)/clutter.range);
      eta = radar.antenna.elementSpacing*cos(angle_graze)/radar.wavelength;
      beta = 2*norm(radar.velocity)*radar.PRI/radar.antenna.elementSpacing;
      
      % Spatial frequency
      freq_spatial = eta*sin(clutter.azimuthCenterPatch);
      % Doppler shift (zero velocity misalignment)
      freq_dopp = beta*eta*sin(clutter.azimuthCenterPatch + 0)*radar.PRF;

      Nc = clutter.nPatches;       % Number of clutter patches in ring
      % Space-time steering vector
      Vc = zeros(radar.nPulses*radar.antenna.nElements, Nc); 
      % Compute the space-time steering vector
      a = radar.antenna.spatialSteeringVector(freq_spatial);
      b = radar.temporalSteeringVector(freq_dopp);
      for ii = 1:Nc
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
    
    function set.angleUnit(obj,val)
      
      validateattributes(val,{'string','char'},{});
      if strncmpi(val,'Degrees',1) && ~strncmpi(obj.angleUnit,'Degrees',1)
        % Convert angle measures to degree
        obj.d_angleUnit = 'Degrees';
        obj.convertToDegree();
      elseif strncmpi(val,'Radians',1) && ~strncmpi(obj.angleUnit,'Radians',1)
        % Convert angle measures to radians
        obj.d_angleUnit = 'Radians';
        obj.convertToRadian();
      end
      
    end
    
    function set.azimuthCenter(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_azimuthCenter = val;
      obj.d_azimuthCenterPatch = (-(obj.azimuthSpan/2-obj.azimuthSpanPatch)+obj.azimuthCenter:...
        obj.azimuthSpanPatch:...
        (obj.azimuthSpan/2)+obj.azimuthCenter).';
      
    end
    
    function set.azimuthCenterPatch(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan'})
      obj.d_azimuthCenterPatch = val;
      
    end
    
    function set.range(obj,val)
      
      obj.d_range = val;
      
    end
    
    function set.earthModel(obj,val)
      
      validateattributes(val,{'string','char'},{});
      obj.d_earthModel = val;
      
    end
        
    function set.azimuthSpan(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_azimuthSpan = val;
      obj.d_azimuthCenterPatch = (-(obj.azimuthSpan/2-obj.azimuthSpanPatch)+obj.azimuthCenter:...
        obj.azimuthSpanPatch:...
        (obj.azimuthSpan/2)+obj.azimuthCenter).';
      
    end
    
    function set.azimuthSpanPatch(obj,val)
      
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'})
      obj.d_azimuthSpanPatch = val;
      obj.d_azimuthCenterPatch = (-(obj.azimuthSpan/2-obj.azimuthSpanPatch)+obj.azimuthCenter:...
        obj.azimuthSpanPatch:...
        (obj.azimuthSpan/2)+obj.azimuthCenter).';
      
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
    
    function out = get.range(obj)
      out = obj.d_range;
    end
    
    function out = get.azimuthCenter(obj)
      out = obj.d_azimuthCenter;
    end
    
    function out = get.azimuthCenterPatch(obj)
      out = obj.d_azimuthCenterPatch;
    end
    
    function out = get.nPatches(obj)
      out = obj.d_azimuthSpan/obj.d_azimuthSpanPatch;
    end
    
    function out = get.earthModel(obj)
      out = obj.d_earthModel;
    end
    
    function out = get.azimuthSpan(obj)
      out = obj.d_azimuthSpan;
    end
    
    function out = get.azimuthSpanPatch(obj)
      out = obj.d_azimuthSpanPatch;
    end
    
  end
  
  %% Hidden Methods
  methods (Hidden)
    
    % Sort the object properties alphabetically
    function value = properties( obj )
      
      % Put the properties list in sorted order
      propList = sort( builtin("properties", obj) );
      % Move any control switch parameters to the top of the output
      switches = {'scale','angleUnit'}';
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