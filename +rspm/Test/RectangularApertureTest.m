classdef RectangularApertureTest < matlab.unittest.TestCase
  
  %% Parameter Setup
  properties
    antenna = RectangularAperture();
    targets = Target();
  end
  
  methods (TestMethodSetup)
    function setupAntenna(testCase)
      % Set up the AbstractAntenna object
      testCase.antenna = RectangularAperture;
      testCase.addTeardown(@RectangularAperture)
      testCase.antenna.center_freq = 3e9;
      testCase.antenna.height = 1.5;
      testCase.antenna.width = 1.5;
      testCase.antenna.mainbeam_direction = [1;0;0];
      testCase.antenna.position = [0;0;0];
    end
    
    function setupTargets(testCase)
      % Set up array of target objects
      num_targets = 3;
      testCase.targets(3,1) = Target();
      for ii = 1:num_targets
        testCase.targets(ii) = Target();
      end
      testCase.targets = testCase.targets';
      % Set each target's position in cartesian coordinates (m)
      testCase.targets(1).position = [20000;0;0];
      testCase.targets(2).position = [10000;0;0];
      testCase.targets(3).position = [10000;10000;10000];
      % Set each target's velocities in cartesian coordinates (m/s)
      testCase.targets(1).velocity = [80;100;400];
      testCase.targets(2).velocity = [0,40,40];
      testCase.targets(3).velocity = [-40;-40;-40];
      % Set each target's RCS (m^2)
      testCase.targets(1).rcs = 10;
      testCase.targets(2).rcs = 10;
      testCase.targets(3).rcs = 10;
    end
  end
  
  %% Tests
  methods (Test)
    
    function testArea(testCase)
      % Test aperture area calculation
      expected = 2.25;
      actual = testCase.antenna.area;
      testCase.verifyEqual(actual,expected)
    end
    
    function testBeamwidthAz3dB(testCase)
      % Test azimuth 3db beamwidth calculation
      
      % Radians mode
      % -----------------------------------------------------------------
      testCase.antenna.angle_unit = 'Radians';
      expected = 0.0593;
      actual = testCase.antenna.beamwidth_azimuth_3db;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      
      % Degrees mode
      % -----------------------------------------------------------------
      testCase.antenna.angle_unit = 'Degrees';
      expected = expected * (180/pi);
      actual = testCase.antenna.beamwidth_azimuth_3db;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
    end
    
    function testBeamwidthEl3dB(testCase)
      % Test elevation 3db beamwidth calculation
      
      % Radians mode
      % -----------------------------------------------------------------
      testCase.antenna.angle_unit = 'Radians';
      expected = 0.0593;
      actual = testCase.antenna.beamwidth_elevation_3db;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      
      % Degrees mode
      % -----------------------------------------------------------------
      testCase.antenna.angle_unit = 'Degrees';
      expected = expected * (180/pi);
      actual = testCase.antenna.beamwidth_elevation_3db;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
    end
    
    function testPowerGain(testCase)
      % Test power gain calculations
      
      % Linear mode
      % -----------------------------------------------------------------
      testCase.antenna.scale = 'linear';
      % Radians mode
      testCase.antenna.angle_unit = 'Radians';
      expected = 2.2471e3;
      actual = testCase.antenna.power_gain;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      % Degrees mode
      % NOTE: The degree expression is just an approximation, so the
      % expected value differs from the true value above
      testCase.antenna.angle_unit = 'Degrees';
      expected = 2252.846;
      actual = testCase.antenna.power_gain;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      
      % dB mode
      % -----------------------------------------------------------------
      testCase.antenna.scale = 'dB';
      testCase.antenna.angle_unit = 'Radians';
      expected = 10*log10(2.2471e3);
      actual = testCase.antenna.power_gain;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      
      testCase.antenna.angle_unit = 'Degrees';
      expected = 10*log10(2252.846);
      actual = testCase.antenna.power_gain;
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
    end
    
    function testnormVoltageGain(testCase)
      % Test normalized pattern gain calculation
      
      % Target positions
      pos_matrix = [testCase.targets.position]';
      
      % Linear mode
      % -----------------------------------------------------------------
      testCase.antenna.scale = 'linear';
      
      % Test Radians mode
      [az,el] = cart2sph(pos_matrix(:,1),pos_matrix(:,2),pos_matrix(:,3));
      testCase.antenna.angle_unit = 'Radians';
      expected = [1;1;0.000894149];
      actual = testCase.antenna.normVoltageGain(az,el);
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      
      % Test degree mode
      az = (180/pi)*az; el = (180/pi)*el;
      testCase.antenna.angle_unit = 'Degrees';
      actual = testCase.antenna.normVoltageGain(az,el);
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      
      % dB mode
      % -----------------------------------------------------------------
      testCase.antenna.scale = 'dB';
      
      % Test Radians mode
      [az,el] = cart2sph(pos_matrix(:,1),pos_matrix(:,2),pos_matrix(:,3));
      testCase.antenna.angle_unit = 'Radians';
      expected = 10*log10([1;1;0.000894149]);
      actual = testCase.antenna.normVoltageGain(az,el);
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)
      
      % Test degree mode
      az = (180/pi)*az; el = (180/pi)*el;
      testCase.antenna.angle_unit = 'Degrees';
      actual = testCase.antenna.normVoltageGain(az,el);
      testCase.verifyEqual(actual,expected,'RelTol',1e-3)

    end

  end
  
end