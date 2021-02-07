% Maintains a constant truth environment for Radar System Parameters. 
% Parameter List:
%   - noise_fig: System noise figure
%   - noise_psd: 

classdef Sys < matlab.mixin.Copyable
  %% Constants
  properties (Constant)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  %% Private Parameters
  properties (Access = private)
    initial_param;       % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
  end
  %% Public Parameters
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
    function obj = Target(target_struct)
      warning('off','MATLAB:structOnObject')
      % Default Constructor
      if nargin == 0
        obj.num_tgts = 0;
        % Struct constructor
      else
        struct_fields = fieldnames(target_struct);
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
            obj.(struct_fields{ii}) = target_struct.(struct_fields{ii});
          end
        end % for
      end % if
    end % function
  end % methods
  %% Setters
  methods

  end % Setters
  %% Private Methods
  methods (Access = private)
    function updateParams(obj, param_name, param_val)
      % No parameter value given. Exit immediately to avoid breaking things
      if isempty(param_val)
        return
      end
      
      switch (param_name)
      end
      
      % Original parameters have updated all its dependent parameters. We
      % can safely empty the list of parameters that have already been
      % updated for the next assignment
      if (strcmp(obj.initial_param, param_name))
        obj.updated_list = {};
      end
    end % updateParams()
    
    function checkIfUpdated(obj, param_name, param_val)
      if ~any(strcmp(param_name, obj.updated_list))
        obj.updated_list{end+1} = param_name;
        obj.updateParams(param_name, param_val);
      end
    end
  end % Private Methods
  
end