% A class representing a linear frequency modulated (LFM) waveform.
%
% TODO:
% - Allow the user to specify direction of the frequency sweep
% 
% Blame: Shane Flandermeyer

classdef LFM < rspm.waveform.AbstractPulsedWaveform
  properties
    pulsewidth; % Sweep interval (s)
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
      
      samp_interval = 1/obj.sampleRate;
      t = (0:samp_interval:obj.pulsewidth-samp_interval)';
      data = exp(1i*2*pi*...
        (-obj.bandwidth/2*t + obj.bandwidth/2/obj.pulsewidth*t.^2));
      % Normalize the data 
      if (strcmpi(obj.normalization,'Energy'))
        data = data ./ norm(data) * obj.timeBandwidthProd;
      elseif (strcmpi(obj.normalization,'Time-Bandwidth'))
        data = data ./ obj.timeBandwidthProd;
      end
      
    end
    
  end % Abstract methods
  
  
  

end
