% A class representing a Radar system
%
% PARAMETERS:
% - antenna: Antenna object
% - waveform: Waveform object
% - prf: Pulse repetition frequency
% - pri: Pulse repetition interval
% - range_unambig: Unambiguous range
% - velocity_unambig: Unambiguous velocity
% - doppler_unambig: Unambiguous doppler
%
% METHODS:
% - measuredRange(obj,targets): Get the range of each target in the list
%                                  measured by the radar
% - measuredVelocity(obj,targets): Get the velocity of each target in
%                                     the list measured by the radar
% - roundTripPhase(obj,targets): Calculate the constant round-trip phase
%                                   term for each target in the list
%
% - receivedPower(obj,targets): Calculates the received power for the
%                                  list of targets from the RRE.
%                                  For now, assuming monostatic configuration
%                                  (G_t = G_r)
% - pulseTrain(obj,num_pulses): Create a pulse train vector of num_pulses
%                               repetitions of the waveform data
% - pulseMatrix(obj,num_pulses): Create a pulse matrix of size
%                                length(waveform.data) x num_pulses, where
%                                each column is a copy of the waveform
% TODO:
% - Allow the user to create a pulse train with multiple types of waveforms
% - Add multistatic capabilities
%
% Blame: Shane Flandermeyer
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
    waveform;          % Transmitted waveform
    prf;               % Pulse repetition frequency
    pri;               % Pulse repetition interval
    num_pulses;
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
    
    function set.waveform(obj,val)
      if (isa(val,'Waveform'))
        obj.waveform = val;
      else
        error('Must be derived from a Waveform object')
      end
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
    
    function range = measuredRange(obj,targets)
      % For each target in the list, calculate the range measured by the
      % radar, accounting for range ambiguities;
      range = obj.trueRange(targets);
      for ii = 1:length(range)
        % Get the projection of the position vector onto the mainbeam pointing
        % vector
        range(ii) = mod(range(ii),obj.range_unambig);
      end
    end % measuredRange()
    
    function range = trueRange(obj,targets)
      % For each target in the list, calculate the true range of the target from
      % the radar
      range = vecnorm([targets(:).position]-obj.antenna.position)';
    end % trueRange()
    
    function doppler = measuredDoppler(obj,targets)
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
    end % measuredDoppler()
    
    function velocity = measuredVelocity(obj,targets)
      % Calculate the velocity measured by the radar for each target in the
      % list. In this case, it's easier to find measured doppler and convert
      % from there
      
      doppler = obj.measuredDoppler(targets);
      velocity = doppler*obj.antenna.wavelength/2;
      
    end % measuredVelocity()
    
    function phase = roundTripPhase(obj,targets)
      
      % Calculate the constant round-trip phase term for each target in the list
      phase = -4*pi*obj.measuredRange(targets)/obj.antenna.wavelength;
      phase = mod(phase,2*pi);
      
    end % roundTripPhase()
    
    function power = receivedPower(obj,targets)
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
      ranges = obj.measuredRange(targets);
      % Calculate the power from the RRE for each target
      power = obj.antenna.tx_power*G.^2*obj.antenna.wavelength^2.*...
        [targets(:).rcs]'./((4*pi)^3*obj.loss_system*ranges.^4);
      
      % Convert back to dB if necessary
      if was_db
        power = 10*log10(power);
        obj.scale = 'db';
      end
    end % receivedPower()
    
    function pulses = pulseTrain(obj)
      % Returns an LM x 1 pulse train, where L is the number of fast time
      % samples of the waveform and M is the number of pulses to be
      % transmitted
      
      % Pad pulse to the PRI length
      num_zeros = (obj.pri-obj.waveform.pulse_width)*obj.waveform.samp_rate;
      padded_pulse = [obj.waveform.data;zeros(num_zeros,1)];
      % Stack num_pulses padded pulses on top of each other
      pulses = repmat(padded_pulse,obj.num_pulses,1);
    end % pulseTrain()
    
    function pulses = pulseMatrix(obj)
      % Returns an L x M pulse train, where L is the number of fast time
      % samples of the waveform and M is the number of pulses to be
      % transmitted
      
      % Pad pulse to the PRI length
      num_zeros = (obj.pri-obj.waveform.pulse_width)*obj.waveform.samp_rate;
      padded_pulse = [obj.waveform.data;zeros(round(num_zeros),1)];
      % Stack num_pulses padded pulses on top of each other
      pulses = repmat(padded_pulse,1,obj.num_pulses);
      
    end % pulseMatrix()
    
    function out = simulateTargets(obj,targets,data)
      
      % Simulate reflections from each target in the list on the given
      % input data, including a time delay, amplitude scaling, and doppler
      % shift.
      %
      % INPUTS:
      %  - targets: The list of target objects
      %  - data: The data in which target responses are injected
      
      % All calculations should be in linear units, so convert to linear if
      % in dB
      was_db = false;
      if (strcmpi(obj.scale,'db'))
        obj.scale = 'linear';
        was_db = true;
      end
      
      % Simulate the response of each target in the list on the input pulses.
      % This response includes the range-dependent target delay, the target
      % amplitude (from the RRE), and the target doppler shift
      
      % Input is a vector. Reshape to a matrix to do the calculations
      was_vector = false;
      if size(data,2) == 1
        data = reshape(data,floor(length(data)/obj.num_pulses),obj.num_pulses);
        was_vector = true;
      end
      
      out = zeros(size(data)); % Pre-allocate the output matrix
      % Loop through all PRIs in the input data and create a scaled and
      % shifted copy for each target. The output for each PRI is the
      % superposition of these pulses
      for ii = 1:obj.num_pulses
        % The true range of each target (used to ensure we don't include
        % ambiguous target returns before the pulse is actually received
        true_ranges = obj.trueRange(targets);
        % The range of each target as seen from the radar
        ranges = obj.measuredRange(targets);
        % The possibly ambiguous sample delays of each target
        delays = (2*ranges/obj.const.c)*obj.waveform.samp_rate;
        % The doppler shifts and amplitude for each target
        dopp_shifts = exp(1i*2*pi*obj.measuredDoppler(targets)*obj.pri*ii);
        amplitude_scaling = sqrt(obj.receivedPower(targets));
        for jj = 1:length(targets)
          % If we have not been transmitting long enough to see a target, its
          % return should not be added into the received signal until we have
          % listened long enough to see it. For example, if a target is at
          % 1.5*r_unambig, it will not be visible until the second pulse.
          if true_ranges(jj) < obj.range_unambig*ii
            % Delay the sequence
            target_return = Radar.delaySequence(data(:,ii),delays(jj));
            % Scale the sequence by the RRE and doppler shift it according to
            % the target doppler
            target_return = target_return*dopp_shifts(jj)*amplitude_scaling(jj);
            % Add the result to the output of the current pulse
            out(:,ii) = out(:,ii) + target_return;
            
            % Shift the target to its position for the next PRI
            targets(jj).position = targets(jj).position + ...
              targets(jj).velocity*obj.pri;
          end
        end
      end
      
      % Convert back to a column vector if necessary
      if was_vector
        out = reshape(out,numel(out),1);
      end
      
      % Convert back to dB if necessary
      if was_db
        obj.scale = 'db';
      end
      
    end % simulateTargets()
    
    function [mf_resp,range_axis] = matchedFilterResponse(obj,data)
      
      % Calculate the matched filter response of the given input data using
      % the waveform object associated with the radar
      %
      % INPUTS:
      %  - data: The fast time data to be filtered. This can be either an
      %          LM x 1 pulse train or an L x M matrix, where L is the
      %          number of fast time samples and M is the number of pulses.
      %
      % OUTPUTS:
      %  - mf_resp: The calculated matched filter response
      %  - range_axis: The ranges corresponding to each delay in the
      %                matched filter output
      
      % Input is a vector. Reshape to a matrix to do the calculations
      if size(data,2) == 1
        data = reshape(data,floor(length(data)/obj.num_pulses),obj.num_pulses);
      end
      
      mf_length = size(obj.waveform.data,1)+size(data,1)-1;
      % Pad the matched filter and data vector (or matrix) to the size of
      % the matched filter output
      mf = [flipud(conj(obj.waveform.data));...
        zeros(mf_length-size(obj.waveform.data,1),1)];
      data = [data;zeros(mf_length-size(data,1),size(data,2))];
      % Calculate the matched filter output in the frequency domain
      mf_resp = zeros(size(data));
      for ii = 1:size(data,2)
        mf_resp(:,ii) = ifft(fft(data(:,ii)).*fft(mf));
      end
      % Calculate the corresponding range axis for the matched filter
      % response, where range 0 corresponds to a sample delay equal to the
      % length of the transmitted waveform
      idx = (1:size(mf_resp,1))';
      time_axis = (idx-length(obj.waveform.data))/obj.waveform.samp_rate;
      range_axis = time_axis*(obj.const.c/2);
      
    end % matchedFilterResponse()
    
    function [rd_map,velocity_axis] = dopplerProcessing(obj,data,oversampling)
      
      % Perform doppler processing on the matched filtered data
      %
      % INPUTS:
      %  - data: A P x M matrix of matched filter vectors, where P is the
      %          length of the matched filter output and M is the number of
      %          pulses.
      %  - oversampling: The doppler oversampling rate
      %
      % OUTPUTS:
      %  - rd_map: The range doppler map
      %  - velocity_axis: The velocity values of each doppler bin
      
      narginchk(2,3);
      % Set default arguments
      if (nargin == 2)
        oversampling = 1;
      end
      
      % Input is a vector. Reshape to a matrix to do the calculations
      if size(data,2) == 1
        data = reshape(data,floor(length(data)/obj.num_pulses),obj.num_pulses);
      end
      % Perform doppler processing over all the pulses
      rd_map = fftshift(fft(data,obj.num_pulses*oversampling,2),2);
%       rd_map = rd_map*obj.num_pulses;
      % Create the doppler axis for the range-doppler map
      velocity_step = 2*obj.velocity_unambig/obj.num_pulses;
      velocity_axis = (-obj.velocity_unambig:velocity_step:...
        obj.velocity_unambig-velocity_step)';
      
    end % dopplerProcessing()
    
    function snr = SNR(obj,targets)
      % Compute the SNR for each target in the input list
      if (strcmpi(obj.scale,'db'))
        snr = obj.receivedPower(targets) - obj.power_noise;
      else
        snr = obj.receivedPower(targets) / obj.power_noise;
      end
    end
  end
  
  %% Static Methods
  methods (Static)
    
    function out = delaySequence(data,delay)
      % Delay the input vector by the given delay
      % INPUTS:
      %  - data: The data to be delayed
      %  - delay: The number of samples to delay the data
      %
      % OUTPUT: The delayed sequence
      delay = round(delay); % Only consider integer sample delays
      delayed_seq_len = size(data,1)+max(0,delay);
      out = zeros(delayed_seq_len,1);
      % Insert the data after the given number of delay samples
      tmp = data;
      out(1+delay:delayed_seq_len) = tmp;
      % Keep the output sequence the same size as the input. All data
      % delayed past the original sequence is truncated.
      out = out(1:length(data),:);
      
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
