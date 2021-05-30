% A class representing a linear frequency modulated (LFM) waveform.
%
% TODO:
% - Allow the user to specify direction of the frequency sweep
% 
% Blame: Shane Flandermeyer

classdef LFM < PulsedWaveform
  properties
    pulse_width; % Sweep interval (s)
    bandwidth;   % Sweep bandwidth (Hz)
  end
  
  %% Getters and setters
  methods
  end
  %% Public methods
  methods (Access = public)
    
    % Create an LFM waveform with the given bandwidth, sample rate, and
    % pulse width, then normalize accordingly
    function data = waveform(obj)
      
      samp_interval = 1/obj.samp_rate;
      t = (0:samp_interval:obj.pulse_width-samp_interval)';
      data = exp(1i*2*pi*...
        (-obj.bandwidth/2*t + obj.bandwidth/2/obj.pulse_width*t.^2));
      % Normalize the data 
      if (strcmpi(obj.normalization,'Energy'))
        data = data ./ norm(data) * obj.time_bandwidth;
      elseif (strcmpi(obj.normalization,'Time-Bandwidth'))
        data = data ./ obj.time_bandwidth;
      end
      
    end
    
  end % Abstract methods
  
  
  

end
