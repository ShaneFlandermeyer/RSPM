% A class representing a simple pulse radar waveform
%
% Blame: Shane Flandermeyer
classdef SimplePulse < rspm.waveform.AbstractPulsedWaveform
  
  %% Private Properties
  
  % Dependent data layer that is exposed to the world
  properties (Dependent)
    pulsewidth; % Pulse duration (s)
    bandwidth;   % Pulse bandwidth (Hz)
  end
  
  % Private data layer that actually stores the value
  properties (Access = private)
    d_pulsewidth;
    d_bandwidth;
  end
  
  
  %% Setters and Getters
  methods
    function out = get.pulsewidth(obj)
      out = obj.d_pulsewidth;
    end
    
    function out = get.bandwidth(obj)
      out = obj.d_bandwidth;
    end
    
    function set.pulsewidth(obj,val)
      obj.d_pulsewidth = val;
      obj.d_bandwidth = 1/obj.pulsewidth;
    end
    
    function set.bandwidth(obj,val)
      obj.d_bandwidth = val;
      obj.d_pulsewidth = 1/obj.bandwidth;
    end
  end
  %% Public methods
  methods (Access = public)
    % Create a simple pulse data vector with the given sample rate and duration
    function data = waveform(obj)
      data = ones(round(obj.sampleRate*obj.pulsewidth),1);
      if strcmpi(obj.normalization, 'Energy')
        data = data ./ norm(data);
      end
    end
  end % Abstract methods
end
