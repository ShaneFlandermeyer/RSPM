classdef AbstractRFSystemTest < matlab.unittest.TestCase
  
  methods(TestClassSetup)
    function [radar,targets] = setup(testCase)
      % Radar System Parameters
      radar = Radar(); % Define a new radar object
      radar.prf = 2e3;                 % Pulse repetition frequency (Hz)
      radar.antenna.center_freq = 3e9; % Center frequency (Hz)
      radar.temperature_noise = 270;   % Input Noise temperature (k)
      radar.antenna.tx_power = 1e3;    % Transmit power (W)
      radar.loss_system = 3;           % System loss (dB)
      radar.noise_fig = 7;             % Noise figure (dB)
      radar.bandwidth = 5e6;           % Receiver bandwidth (Hz)
      % AbstractAntenna Parameters
      radar.antenna.width = 1.5;   % Width of the aperture
      radar.antenna.height = 1.5;  % Height of the aperture
      radar.antenna.azimuth = 0;   % Azimuth pointing angle (theta_0)
      radar.antenna.elevation = 0; % Elevation pointing angle (phi_0)
      % Target parameters
      num_targets = 3;
      targets(num_targets) = Target();
      targets = targets';
      % Set each target's position in cartesian coordinates (m)
      targets(1).position = [20000;0;0];
      targets(2).position = [10000;0;0];
      targets(3).position = [10000;10000;10000];
      % Set each target's velocities in cartesian coordinates (m/s)
      targets(1).velocity = [80;100;400];
      targets(2).velocity = [0,40,40];
      targets(3).velocity = [-40;-40;-40];
      % Set each target's RCS (m^2)
      targets(1).rcs = 10;
      targets(2).rcs = 10;
      targets(3).rcs = 10;
    end
  end
  
  methods (Test)
    
    function testReceivedPower(testCase)
      [radar,targets] = setup(testCase);
      radar.scale = 'linear';
      %% Calculate with the radar object
      actual = radar.receivedPower(targets);
      % Values calculated outside of the object
      expected = [7.950323912178896e-13;1.272051825948623e-11;9.034488617508329e-25];
      testCase.verifyEqual(expected,actual,'AbsTol',100*eps)
      
      radar.scale = 'db';
      actual = radar.receivedPower(targets);
      expected = 10*log10(expected);
      testCase.verifyEqual(expected,actual,'RelTol',1e-4)
    end
    
    function testSNR(testCase)
      [radar,targets] = setup(testCase);
      expected = [8.510740162895264;1.361718426063242e+02;9.671327354406549e-12];
      radar.scale = 'linear';
      actual = radar.SNR(targets);
      testCase.verifyEqual(actual,expected,'RelTol',1e-2)
      radar.scale = 'db';
      actual = radar.SNR(targets);
      expected = 10*log10(expected);
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
    end
    
  end
  
end