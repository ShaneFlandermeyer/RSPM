classdef Radar < matlab.mixin.Copyable & RFSystem
  %% Properties
  % Constants
  properties (Constant = true)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  
  % Private properties
  properties (Access = private)
    
    initial_param; % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
    % List of parameters that should be updated when we change the scale
    % from linear to dB or vice versa
    power_list = {'loss_system','noise_fig'};
  end
  
  properties (Access = public)
    antenna = Antenna();
    prf;               % Pulse repetition frequency
    pri;               % Pulse repetition interval
  end
  
  % Dependent properties: These cannot be set correctly, and are
  % automatically calculated based on other parameters
  properties (Dependent)
    range_unambig;
    velocity_unambig;
    doppler_unambig;
  end
  
  %% Setter methods
  methods
    
    function set.prf(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.prf = val;
      obj.checkIfUpdated('prf',val);
    end
    
    function set.pri(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.pri = val;
      obj.checkIfUpdated('pri',val);
    end
    
    
  end
  
  %% Getter Methods
  methods
    
    % Calculate the unambiguous velocity
    function val = get.velocity_unambig(obj)
      val = obj.antenna.wavelength*obj.prf/4;
    end
    
    % Calculate the unambiguous range
    function val = get.range_unambig(obj)
      val = obj.const.c*obj.pri/2;
    end
    
    % Cac
    function val = get.doppler_unambig(obj)
      val = obj.prf/2;
    end
    
  end
  
  %% Public Methods
  methods
    
    
    function range = getMeasuredRange(obj,targets)
      % For each target in the list, calculate the range measured by the
      % radar, accounting for range ambiguities;
      range = obj.getTrueRange(targets);
      for ii = 1:length(range)
        % Get the projection of the position vector onto the mainbeam pointing
        % vector
        range(ii) = mod(range(ii),obj.range_unambig);
      end
    end
    
    function range = getTrueRange(obj,targets)
      % For each target in the list, calculate the true range of the target from
      % the radar
      range = vecnorm([targets(:).position]-obj.antenna.position)';
    end
    
    
    function doppler = getMeasuredDoppler(obj,targets)
      % Calculate the measured doppler shift of each target in the list,
      % accounting for ambiguities
      
      doppler = zeros(numel(targets),1); % Pre-allocate
      for ii = 1:length(doppler)
        % Calculate the shift that would be measured with no ambiguities.
        % NOTE: We define negative doppler as moving towards the radar, so there
        % is a sign change.
        position_vec = targets(ii).position - obj.antenna.position;
        position_vec = position_vec / norm(position_vec);
        true_doppler = -dot(targets(ii).velocity,position_vec)*...
          2/obj.antenna.wavelength;
        
        if (abs(true_doppler) < obj.prf/2)
          % Shift can be measured unambiguously, send it straight to the
          % output
          doppler(ii) = true_doppler;
        elseif mod(true_doppler,obj.prf) < obj.prf/2
          % Aliased doppler is within the measurable range; output it
          aliased_doppler = mod(true_doppler,obj.prf);
          doppler(ii) = aliased_doppler;
        elseif mod(true_doppler,obj.prf) > obj.prf/2
          % Aliased doppler is still ambiguous. Shift it into the measurable
          % range
          aliased_doppler = mod(true_doppler,obj.prf);
          doppler(ii) = aliased_doppler-obj.prf;
        end % if
      end % for
    end % function
    
    
    function velocity = getMeasuredVelocity(obj,targets)
      % Calculate the velocity measured by the radar for each target in the
      % list. In this case, it's easier to find measured doppler and convert
      % from there
      
      doppler = obj.getMeasuredDoppler(targets);
      velocity = doppler*obj.wavelength/2;
    end
    
    function phase = getRoundTripPhase(obj,targets)
      % Calculate the constant round-trip phase term for each target in the list
      phase = -4*pi*obj.getMeasuredRange(targets)/obj.antenna.wavelength;
      phase = mod(phase,2*pi);
    end
    
    function power = getReceivedPower(obj,targets)
      % Calculates the received power for the list of targets from the RRE.
      % For now, assuming monostatic configuration (G_t = G_r)
      
      % Convert everything to linear for our calculations, but keep track of
      % whether or not we need to go back to dB
      was_db = false;
      if (strcmpi(obj.scale,'db'))
        obj.scale = 'linear';
        was_db = true;
      end
      
      % Get the azimuth and elevation of the targets
      pos_matrix = [targets.position]';
      [az,el] = cart2sph(pos_matrix(:,1),pos_matrix(:,2),pos_matrix(:,3));
      % Convert to degree if necessary
      if strncmpi(obj.antenna.angle_unit,'Degree',1)
        az = (180/pi)*az;
        el = (180/pi)*el;
      end
      
      % Get the antenna gain in the azimuth/elevation of the targets. Also
      % convert to linear units if we're working in dB
      G = obj.antenna.power_gain*obj.antenna.getNormPatternGain(az,el).^2;
      % Get the target ranges as seen by the radar
      ranges = obj.getMeasuredRange(targets);
      % Calculate the power from the RRE for each target
      power = obj.antenna.tx_power*G.^2*obj.antenna.wavelength^2.*...
        [targets(:).rcs]'./((4*pi)^3*obj.loss_system*ranges.^4);
      
      % Convert back to dB if necessary
      if was_db
        power = 10*log10(power);
        obj.scale = 'db';
      end
    end
    
  end
  
  %% Private Methods
  methods (Access = private)
    
    function updateParams(obj, param_name, param_val)
      % A helper functions to update dependent parameters that can't be
      % marked explicitly dependent. For example, the prf should be able to
      % update the pri and vice versa, so the user should be able to change
      % either of them
      
      % No parameter value given. Exit immediately to avoid breaking things
      if isempty(param_val)
        return
      end
      
      switch (param_name)
        case 'prf'
          obj.pri = 1/obj.prf;
        case 'pri'
          obj.prf = 1/obj.pri;
      end
      
      % Original parameters have updated all its dependent parameters. We
      % can safely empty the list of parameters that have already been
      % updated for the next assignment
      if (strcmp(obj.initial_param, param_name))
        obj.updated_list = {};
      end
    end % updateParams()
    
    
    function checkIfUpdated(obj, param_name, param_val)
      % Check if the given parameter has already been updated in a recursive
      % updateParams call. If it hasn't, add it to the list and update it
      if ~any(strcmp(param_name, obj.updated_list))
        if isempty(obj.updated_list)
          obj.initial_param = param_name;
        end
        obj.updated_list{end+1} = param_name;
        obj.updateParams(param_name, param_val);
      end
    end
    
  end
end
