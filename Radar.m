classdef Radar < matlab.mixin.Copyable & RFSystem
  %% Properties
  % Constants
  properties (Constant = true)
    const = struct('c',299792458,'k',1.38064852e-23,'T0_k',290)
  end
  
  % Private properties
  properties (Access = private)
    
    initial_param; % First parameter updated in updateParams()
    updated_list = {}; % List of parameters updated due to initial_param
    % List of parameters that should be updated when we change the scale
    % from linear to dB or vice versa
    % TODO: Make separate arrays for voltage v. power quantities
    db_list = {'loss_system','noise_fig'}; 
    
  end
  properties (Access = public)
    antenna = Antenna();
    prf;               % Pulse repetition frequency
    pri;               % Pulse repetition interval
    
  end
  
  % Dependent properties: These cannot be set correctly, and are
  % automatically calculated based on other parameters
  properties (Dependent)
    range_unambig;
    velocity_unambig;
    doppler_unambig;
  end
  
  %% Setter methods
  methods
    function set.prf(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.prf = val;
      obj.checkIfUpdated('prf',val);
    end
    
    function set.pri(obj,val)
      validateattributes(val,{'numeric'},{'finite','nonnan','nonnegative'});
      obj.pri = val;
      obj.checkIfUpdated('pri',val);
    end
    
    
  end
  
  %% Getter Methods
  methods
    
    function val = get.velocity_unambig(obj)
      val = obj.wavelength*obj.prf/4;
    end
    
    function val = get.range_unambig(obj)
      val = obj.const.c*obj.pri/2;
    end
    
    function val = get.doppler_unambig(obj)
      val = obj.prf/2;
    end
    
  end
  
  %% Public Methods
  methods
    
    % For each target in the list, calculate the range measured by the
    % radar, accounting for range ambiguities;
    function range = getMeasuredRange(obj,targets)
      range = zeros(numel(targets),1); % Pre-allocate
      for ii = 1:length(range)
        range(ii) = mod(dot(targets(ii).position,obj.antenna.position),...
          obj.range_unambig);
      end
    end
    
    % Calculate the measured doppler shift of each target in the list,
    % accounting for ambiguities
    function doppler = getMeasuredDoppler(obj,targets)
      doppler = zeros(numel(targets),1); % Pre-allocate
      for ii = 1:length(doppler)
        % Calculate the shift that would be measured with no ambiguities
        true_doppler = dot(targets(ii).velocity,obj.antenna.position)*...
          2/obj.wavelength;
        % Shift can be measured unambiguously, send it straight to the
        % output
        if (abs(true_doppler) < obj.prf/2)
          doppler(ii) = true_doppler;
        else
          % Measured shift is ambiguous; shift it into the measurable range
          aliased_doppler = mod(true_doppler,obj.prf);
          doppler(ii) = aliased_doppler-obj.prf;
        end
      end
    end
    
    % Calculate the velocity measured by the radar for each target in the
    % list. In this case, it's easier to find measured doppler and convert
    % from there
    function velocity = getMeasuredVelocity(obj,targets)
      doppler = obj.getMeasuredDoppler(targets);
      velocity = doppler*obj.wavelength/2;
    end
    
    
    
  end
  %% Private Methods
  methods (Access = private)
    
    % A helper functions to update dependent parameters that can't be
    % marked explicitly dependent. For example, the prf should be able to
    % update the pri and vice versa, so the user should be able to change
    % either of them 
    function updateParams(obj, param_name, param_val)
      % No parameter value given. Exit immediately to avoid breaking things
      if isempty(param_val)
        return
      end
      
      switch (param_name)
        case 'prf'
          obj.pri = 1/obj.prf;
        case 'pri'
          obj.prf = 1/obj.pri;
      end
      
      % Original parameters have updated all its dependent parameters. We
      % can safely empty the list of parameters that have already been
      % updated for the next assignment
      if (strcmp(obj.initial_param, param_name))
        obj.updated_list = {};
      end
    end % updateParams()
    
    % Check if the given parameter has already been updated in a recursive
    % updateParams call. If it hasn't, add it to the list and update it
    function checkIfUpdated(obj, param_name, param_val)
      if ~any(strcmp(param_name, obj.updated_list))
        obj.updated_list{end+1} = param_name;
        obj.updateParams(param_name, param_val);
      end
    end
    
  end
end