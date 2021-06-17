% An abstract class representing a pulsed radar waveform.
%
% Blame: Shane Flandermeyer

classdef (Abstract) AbstractPulsedWaveform < rspm.waveform.AbstractWaveform
  properties (Abstract)
    pulsewidth;     % Length of the pulse in seconds  
  end
  
  properties (Dependent, Access = public)
    timeBandwidthProd;  % Time-bandwidth product for the waveform
  end
  
  %% Getters/Setters
  methods
    function bt = get.timeBandwidthProd(obj)
      % Calculate the time-bandwidth product of the waveform
      bt = obj.pulsewidth*obj.bandwidth;
    end
  end
 
  %% Public Methods
  methods (Access = public)
    function [af,t,fd] = ambiguityFunction(obj)
      % Calculate the ambiguity function for the given waveform
      %
      % INPUT: A waveform object
      % 
      % OUTPUTS: 
      %  - af: An L x M matrix of values corresponding to each delay and doppler
      %        of the ambiguity function, where L is the number of delay points
      %        and M is the number of doppler points
      %
      %  - t: The L x 1 delay axis
      %
      %  - fd: The M x 1 doppler axis
      %
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
      t = delays/obj.sampleRate;
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
        % Shift forward in time
        v(1:length(x)-tau) = x(1+tau:length(x));
      else
        % Shift backward in time
        v(1-tau:length(x)) = x(1:length(x)+tau);
      end
    end
  end
end % Classdef
