classdef SimplePulse < PulsedWaveform
  
  %% Private Properties
  
  % Private data layer that actually stores the value
  properties (Access = private)
    d_pulse_width;
    d_bandwidth;
  end
  
  % Dependent data layer that is exposed to the world
  properties (Dependent)
    pulse_width;
    bandwidth;
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
    % Create an LFM waveform with the given bandwidth, sample rate, and
    % pulse width. This waveform is normalized to have unit energy
    function data = waveform(obj)
      data = ones(round(obj.samp_rate*obj.pulse_width),1);
    end
  end % Abstract methods
end