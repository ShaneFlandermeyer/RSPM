# radar-object
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
**TODO**

## LFM
**TODO**

## PulsedWaveform
**TODO**

## Radar

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
- **simulateTargets(obj, targets, data):** Given a list of targets and sampled input data, returns the superposition of all targets' delay, doppler shift and amplitude scaling on the data
- **matchedFilterResponse(obj, data):** Returns the matched filter response of the input data, where the matched filter is calculated from the waveform parameter
- **dopplerProcessing(obj, data, oversampling):** Performs doppler processing on the given input data, where the doppler bins are oversampled by the given oversampling factor
- **SNR(obj, targets):** Given a list of target objects, returns the SNR for each target (before range-doppler processing, not accounting for the waveform)

## RFSystem

**TODO**

## SimplePulse

**TODO**

## Target

**TODO**

## Waveform

**TODO**
