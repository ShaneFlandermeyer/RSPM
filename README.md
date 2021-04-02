# Object-Oriented Radar Simulation Tools

The object-oriented paradigm seems like a natural choice for radar signal
processing simulations since it encourages code reuse for common operations and
provides a more intuitive representation of real life than functional programming,
         but I haven't seen it used in many codebases. This repository seeks to create
         a set of compatible objects that can be used for a variety of simulation environments.
         The effort seems patchwork because it is; any time I implement a useful feature
         in a class, my research or my free time, I port it to an object.

The following objects have currently been implemented

## Antenna
<<<<<<< HEAD
**TODO**
=======
**TODO: This parameter is going to be broken up into many objects soon, so I'm punting on the documentation here**
>>>>>>> dcf14381961a293e0993cd6856e36fef6d494aa3

## LFM < PulsedWaveform
A linear frequency modulated waveform object

TODO: Currently only allows for upchirps about complex baseband

### Parameters
- **pulse_width:** The chirp duration (s)

- **bandwidth:** Sweep bandwidth (Hz)
### Methods
- **waveform(obj):** Creates an LFM waveform from the object parameters

## PulsedWaveform < Waveform

An Abstract class representing a pulsed radar waveform

### Parameters
- **pulse_width:** The duration of the pulse (s)

- **time_bandwidth:** The time-bandwidth product of the waveform

### Methods
- **ambiguityFunction:** Computes the ambiguity function for the waveform

## Radar < RFSystem

An object that holds all information about the radar being simulated. This is sorta a god object, and can contain instances of all other objects.

### Parameters
- **antenna:** The antenna object used for the simulation. For now, only a monostatic configuration is supported.

- **doppler_unambig:** The unambiguous doppler frequency (Hz)
- **num_pulses:** The number of pulses in a CPI
- **PRF:** Pulse repetition frequency (Hz)
- **PRI:** Pulse repetition interval (s)
- **range_unambig:** The unambiguous range (m)
- **velocity_unambig:** The unambiguous velocity (m/s)
- **waveform:** The waveform object used for the simulation. For now, it is assumed that only one waveform is used

### Methods
- **measuredRange(obj, targets):** Given a list of target objects, returns the range measured by the radar (i.e., accounting for ambiguities)

- **trueRange(obj, targets):** Given a list of target objects, returns the true range 
of the targets relative to the radar
- **measuredDoppler(obj, targets):** Given a list of target objects, returns the doppler shift measured by the radar (i.e., accounting for ambiguities)
- **measuredVelocity(obj, targets):** Given a list of target objects, returns the velocity measured by the radar (i.e., accounting for ambiguities)
- **roundTripPhase(obj, targets):** Given a list of target objects, returns the "round trip" phase term from the target range
- **receivedPower(obj, targets):** Given a list of target objects, returns the power received according to the radar range equation
- **pulseTrain(obj):** Returns an LM x 1 pulse train of the waveform parameter object, where L is the number of fast time samples in a PRI and M is the
number of pulses
- **pulseMatrix(obj):** Returns an L x M matrix of copies of the waveform parameter object, where L is the number of fast time samples and M is the number of pulses
<<<<<<< HEAD
- **simulateTargets(obj, targets, data):** Given a list of targets and sampled input data, returns the superposition of all targets' delay, doppler shift and amplitude scaling on the data
=======
- **simulateTargets(obj, targets, data):** Given a list of targets and sampled input data,  returns the superposition of all targets' delay, doppler shift and amplitude scaling on the data by scaling and shifting on the pulse level
- **simulateTargetsPulseBurst(obj, targets, data):** Given a list of targets and sampled input data, returns the superposition of all targets' delay, doppler shift and amplitude scaling on the data by scaling and shifting on the sample level
>>>>>>> dcf14381961a293e0993cd6856e36fef6d494aa3
- **matchedFilterResponse(obj, data):** Returns the matched filter response of the input data, where the matched filter is calculated from the waveform parameter
- **dopplerProcessing(obj, data, oversampling):** Performs doppler processing on the given input data, where the doppler bins are oversampled by the given oversampling factor
- **SNR(obj, targets):** Given a list of target objects, returns the SNR for each target (before range-doppler processing, not accounting for the waveform)

## RFSystem

<<<<<<< HEAD
**TODO**
=======
An abstract class representation of an RF front end

### Parameters:
- **bandwidth:** The receiver bandwidth (Hz)

- **loss_system:** System loss factor
- **noise_fig:** System noise figure
- **power_noise:** The receiver noise power
- **scale:** Specifies whether parameters should be given in linear or dB scale
- **temperature_noise:** Input noise temperature

### Methods
- **addThermalNoise(obj,data):** Adds thermal noise to the input data based on the system noise power.
>>>>>>> dcf14381961a293e0993cd6856e36fef6d494aa3

## SimplePulse < PulsedWaveform

### Methods
- **waveform(obj):** Creates a simple pulse waveform with the parameters given by the object

## Target

An object representing a target. For now, this is just a point target

### Parameters
- **position:** The target's position in XYZ cartesian coordinates

- **velocity:** The target's velocity in XYZ cartesian coordinates
- **rcs:** The target's radar cross section (m<sup>2</sup>)

## Waveform

An abstract class representing a waveform (not necessarily just for radar)

### Parameters
- **samp_rate:** The ADC sample rate (samples/s). It may seem like this parameter belongs with the RFSystem object, but it is needed to generate the waveform data and there's no way to make that inheritance make sense

- **normalization:** Defines the waveform normalization. The following options are allowed:
  - 'None': No normalization
  - 'Energy': Normalize the waveform to have unit energy
  - 'Time-Bandwidth:' Normalize the waveform by time-bandwidth product
