# Radar Simulation Parameter Manager (RSPM)

Radar simulations necessarily involve many interdependent parameters. For complex scenarios, lots of developer effort is spent making sure the relationships between parameters are maintained throughout the simulation. RSPM uses Matlab's object-oriented programming (OOP) framework to address this issue by maintaining a constant truth environment, making it impossible to generate an invalid set of parameters. This is accomplished by implementing the relationships in objects so that when one parameter is changed, all its dependent parameters are also changed automatically. This method also promotes code reuse and reduces the opportunity for user error since relationships only need to be implemented once rather than in every simulation.

The following objects have been implemented

## Antennas
- AbstractAntenna: Base class for individual antenna element objects
- CosineAntennaElement: Antenna with a 2D cosine beampattern
- RectangulaAntennaElement: Rectangular aperture with a 2D sinc beampattern
- AbstractAntennaArray: Base class for array antenna objects
- LinearArray: A uniform linear array (ULA) with user-specified element patterns

## Clutter
- AbstractClutter: Base class for clutter objects
- ConstantGammaClutter: Gaussian clutter whose reflectivity is given by the constant-gamma model

## Jammers
- AbstractJammer: Base class for jammer objects
- BarrageJammer: Jammer localized in angle but whose signal is spread through the doppler spectrum

## Systems
- AbstractRFSystem: Base class for system objects
- Radar: A radar system composed of many RSPM objects

## Targets
- AbstractTarget: Base class for target objects
- Point target: A constant-RCS point target

## Waveform
- AbstractWaveform: Base class for waveform objects
- AbstractPulsedWaveform: Base class for pulsed waveform objects
- SimplePulse: A simple (rectangular) pulse with some pulse width
- LFM: A linear frequency modulated (LFM) chirp waveform

