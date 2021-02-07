classdef Radar < matlab.mixin.Copyable
  
  %% Constants
  properties (Constant)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  %% Private Parameters
  properties (Access = private)
    initial_param;       % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
  end
  %% Parameter objects
  properties
    antenna = Antenna();
    target = Target();
    waveform = Waveform();
  end
  %% System parameters
  properties
    noise_psd; % Noise Power Spectral Density (W/Hz)
    pwr_noise; % Noise Power (W)
    noise_fig; % Noise figure
    samp_rate; % Sample Rate (Samps/sec)
  end
%% Constructor
  methods
    % The default constructor creates a monostatic antenna configuration.
    % The other constructor takes a struct as an argument and assigns
    % values to the object for all fields common to both the struct and the
    % object.
    function obj = Radar(radar_struct)
      warning('off','MATLAB:structOnObject')
      % Default Constructor
      if nargin == 0
        % Struct constructor
      else
        struct_fields = fieldnames(radar_struct);
        obj_fields = fieldnames(obj);
        % If we find fields for the constant struct or private parameters,
        % don't pass them in
        const_idx = ismember(struct_fields,'const');
        list_idx = ismember(struct_fields,'updated_list');
        ori_idx = ismember(struct_fields,'initial_param');
        if (any(const_idx))
          struct_fields{const_idx} = [];
        end
        if (any(list_idx))
          struct_fields{list_idx} = [];
        end
        if (any(ori_idx))
          struct_fields{ori_idx} = [];
        end
        % Loop through all fields in the struct; if a field name is common
        % to both the struct and the object, assign the value from the
        % struct field to the object field
        for ii = 1:length(struct_fields)
          if any(strcmp(struct_fields{ii},obj_fields))
            obj.(struct_fields{ii}) = radar_struct.(struct_fields{ii});
          end
        end % for
      end % if
    end % function
  end % methods
end
