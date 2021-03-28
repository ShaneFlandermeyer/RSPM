% An abstract class representing a pulsed radar waveform.
%
% PARAMETERS:
% - pulse_width: The length of the pulse in seconds
% - time_bandwidth: The time-bandwidth product of the waveform
%
% PUBLIC METHODS
% - ambiguityFunction(): Calculates the ambiguity function for the waveform

classdef (Abstract) PulsedWaveform < Waveform
  properties (Abstract)
    pulse_width;     % Length of the pulse in seconds  
  end
  
  properties (Dependent, Access = public)
    time_bandwidth;  % Time-bandwidth product for the waveform
  end
  
  %% Abstract Methods
  methods (Abstract)
  end
  %% Getters/Setters
  methods
    function bt = get.time_bandwidth(obj)
      bt = obj.pulse_width*obj.bandwidth;
    end
  end
 
  %% Public Methods
  methods (Access = public)
    function [af,t,fd] = ambiguityFunction(obj)
      % No waveform generated
      delays = (-(length(obj.data)-1):(length(obj.data)-1))';
      num_delays = length(delays);
      % Number of doppler points
      num_doppler = 2^nextpow2(num_delays);
      % Create a doppler vector spanning from [-bandwidth,bandwidth]
      fd = linspace(-obj.bandwidth,obj.bandwidth,num_doppler)';
      % Calculate the ambiguity function for each delay with an IDFT
      af = zeros(num_delays,num_doppler);
      for ii = 1:num_delays
        % Shift the matched filter response by delays(ii) samples
        v = obj.localshift(obj.data,delays(ii));
        % Compute a num_doppler-point IDFT
        af(ii,:) = abs(ifftshift(ifft(obj.data.*conj(v),num_doppler)));
      end
      af = af*num_doppler; % Scaling factor
      t = delays/obj.samp_rate;
    end
  end

  %% Private Methods
  methods (Access = private)
    % Shifts a vector x by tau samples
    function v = localshift(~,x,tau)
      vreal = zeros(length(x),1);
      if ~isreal(x)
        v = complex(vreal);
      else
        v = vreal;
      end
      if tau >= 0
        v(1:length(x)-tau) = x(1+tau:length(x));
      else
        v(1-tau:length(x)) = x(1:length(x)+tau);
      end
    end
  end
end % Classdef