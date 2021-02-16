classdef CFARDetector
  properties
    method; % CFAR Algorithm to be used
    num_guard_cells; % Number of Guard Cells
    num_train_cells; % Number of training cells
    pfa;             % Probability of False alarm
  end
  
  methods
    
    
    function obj = set.num_guard_cells(obj,val)
      validateattributes(val, {'numeric'},...
      {'integer','finite','nonnan','nonnegative'},'','num_guard_cells');
      obj.num_guard_cells = val;
    end
    
    
    function obj = set.num_train_cells(obj,val)
      validateattributes(val, {'numeric'},...
      {'integer','finite','nonnan','positive'},'','num_train_cells');
      obj.num_train_cells = val;
    end
    
    
  end 
end