% A class representing a Radar system
%
% TODO:
% - Allow the user to create a pulse train with multiple types of waveforms
% - Add multistatic capabilities
%
% Blame: Shane Flandermeyer
classdef Radar < matlab.mixin.Copyable & RFSystem
  
  %% Private properties
  properties (Access = private)
    % List of parameters that should be updated when we change the scale
    % from linear to dB or vice versa
    power_list = {'loss_system','noise_fig'};
  end
  
  % Members exposed to the outside world
  properties (Dependent)
    antenna;          % Antenna object
    waveform;         % Waveform object
    prf;              % Pulse repetition frequency (Hz)
    pri;              % Pulse repetition interval (s)
    num_pulses;       % Number of pulses in a CPI
    range_unambig;    % Unambiguous range (m)
    velocity_unambig; % Unambiguous velocity (m/s)
    doppler_unambig;  % Unambiguous doppler frequency (Hz)
    range_resolution; % Range resolution (m)
  end
  
  % Internal class data
  properties (Access = protected)
    d_antenna;
    d_waveform;
    d_prf;
    d_pri;
    d_num_pulses;
  end

  
  %% Setter Methods
  methods
    
    function set.num_pulses(obj,val)
      obj.d_num_pulses = val;
    end
    
    function set.prf(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_prf = val;
      obj.d_pri = 1 / obj.d_prf;
    end
    
    function set.pri(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.d_pri = val;
      obj.d_prf = 1 / obj.d_pri;
    end
    
    function set.waveform(obj,val)
      if (isa(val,'Waveform'))
        obj.d_waveform = val;
      else
        error('Must be derived from a Waveform object')
      end
    end
    
    function set.antenna(obj,val)
      if (isa(val,'Antenna') || isa(val,'AntennaArray'))
        obj.d_antenna = val;
      else
        error('Must be derived from an Antenna or AntennaArray object')
      end
    end
        
  end
  
  %% Getter Methods
  methods   
    
    function out = get.range_resolution(obj)
      out = obj.const.c/2/obj.bandwidth;
    end
    
    function out = get.num_pulses(obj)
      out = obj.d_num_pulses;
    end
    
    function out = get.prf(obj)
      out = obj.d_prf;
    end
    
    function out = get.pri(obj)
      out = obj.d_pri;
    end
    
    function out = get.waveform(obj)
      out = obj.d_waveform;
    end
    
    function out = get.antenna(obj)
      out = obj.d_antenna;
    end
    
    function out = get.doppler_unambig(obj)
      % Calculate the unambiguous doppler
      out = obj.prf/2;
    end
   
    function out = get.range_unambig(obj) 
      % Calculate the unambiguous range
      out = obj.const.c*obj.pri/2;
    end
    
    function out = get.velocity_unambig(obj)
      % Calculate the unambiguous velocity
      out = obj.antenna.wavelength*obj.prf/4;
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
      G = obj.antenna.power_gain*obj.antenna.normVoltageGain(az,el).^2;
      % Get the target ranges as seen by the radar
      ranges = obj.trueRange(targets);
      % Calculate the power from the RRE for each target
      power = obj.antenna.tx_power*G.^2*obj.antenna.wavelength^2.*...
        [targets(:).rcs]'./((4*pi)^3*obj.loss_system*ranges.^4);
      
      % Convert back to dB if necessary
      if was_db
        power = 10*log10(power);
        obj.scale = 'db';
      end
    end % receivedPower()
    
    function pulses = pulseBurstWaveform(obj)
      % Returns an LM x 1 pulse train, where L is the number of fast time
      % samples of the waveform and M is the number of pulses to be
      % transmitted
      
      % Pad pulse to the PRI length
      num_zeros = (obj.pri-obj.waveform.pulse_width)*obj.waveform.samp_rate;
      padded_pulse = [obj.waveform.data;zeros(num_zeros,1)];
      % Stack num_pulses padded pulses on top of each other
      pulses = repmat(padded_pulse,obj.num_pulses,1);
    end % pulseBurstWaveform()
    
    function mf = pulseBurstMatchedFilter(obj)
      % Returns an LM x 1 pulse train containing M copies of the length-L
      % matched filter vector
      mf = flipud(conj(obj.pulseBurstWaveform()));
    end % pulseBurstMatchedFilter()
    
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
    
    function out = simulateTargetsPulseBurst(obj,targets,data)
      % Simulate the effects of each target in the list on the input pulse burst
      % waveform. Target effects are applied on a per-sample basis, but the stop
      % and hop model is assumed so the amplitudes, delays, and doppler shifts
      % are only calculated once per pulse. This method produces an identical
      % output as simulateTargets(), but it's about 10x slower so it isn't
      % actually used in project 2.
      
      was_db = false;
      if (strcmpi(obj.scale,'db'))
        obj.scale = 'linear';
        was_db = true;
      end
      
      % Time indices of the start of each pulse
      Tadc = 1/obj.waveform.samp_rate;
      t = (0:Tadc:obj.pri*obj.num_pulses-Tadc)';
      pri_length = obj.pri*obj.waveform.samp_rate;
      out = zeros(size(data));
      % Get the shifted returns for each target then sum them together
      measured_range = 0;
      delay = 0;
      dopp_shift = 0;
      amplitude = 0;
      for ii = 1:length(targets)
        for jj = 1:numel(data)
          % Calculate new target parameters ONLY on the first sample of each new
          % pulse (stop and hop assumption)
          if (jj == 1 || ~mod(jj,pri_length))
            measured_range = obj.measuredRange(targets(ii));
            delay = round((2*measured_range/obj.const.c)*obj.waveform.samp_rate);
            dopp_shift = exp(1i*2*pi*obj.trueDoppler(targets(ii))*t(jj));
            amplitude = sqrt(obj.receivedPower(targets(ii)));
          end
          % Scale and shift each sample according to the above calculations
          if jj > delay
            out(jj) = out(jj) + data(jj-delay)*amplitude*dopp_shift;
          end
        end
      end
      
      % Convert back to dB if necessary
      if was_db
        obj.scale = 'db';
      end
    end % simulateTargetsPulseBurst()
    
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
      waveform_norm = obj.waveform.data ./ norm(obj.waveform.data);
      mf = [flipud(conj(waveform_norm));...
        zeros(mf_length-size(waveform_norm,1),1)];
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
  
end
