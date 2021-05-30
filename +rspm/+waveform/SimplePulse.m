% A class representing a simple pulse radar waveform
%
% Blame: Shane Flandermeyer
classdef SimplePulse < PulsedWaveform
  
  %% Private Properties
  
  % Dependent data layer that is exposed to the world
  properties (Dependent)
    pulse_width; % Pulse duration (s)
    bandwidth;   % Pulse bandwidth (Hz)
  end
  
  % Private data layer that actually stores the value
  properties (Access = private)
    d_pulse_width;
    d_bandwidth;
  end
  
  
  %% Setters and Getters
  methods
    function out = get.pulse_width(obj)
      out = obj.d_pulse_width;
    end
    
    function out = get.bandwidth(obj)
      out = obj.d_bandwidth;
    end
    
    function set.pulse_width(obj,val)
      obj.d_pulse_width = val;
      obj.d_bandwidth = 1/obj.pulse_width;
    end
    
    function set.bandwidth(obj,val)
      obj.d_bandwidth = val;
      obj.d_pulse_width = 1/obj.bandwidth;
    end
  end
  %% Public methods
  methods (Access = public)
    % Create a simple pulse data vector with the given sample rate and duration
    function data = waveform(obj)
      data = ones(round(obj.samp_rate*obj.pulse_width),1);
      if strcmpi(obj.normalization, 'Energy')
        data = data ./ norm(data);
      end
    end
  end % Abstract methods
end
