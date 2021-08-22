# Radar Simulation Parameter Manager (RSPM)

NOTE: This repository has been archived

Radar simulations necessarily involve many interdependent parameters. For complex scenarios, lots of developer effort is spent making sure the relationships between parameters are maintained throughout the simulation. RSPM uses Matlab's object-oriented programming (OOP) framework to address this issue by maintaining a constant truth environment, making it impossible to generate an invalid set of parameters. This is accomplished by implementing the relationships in objects so that when one parameter is changed, all its dependent parameters are also changed automatically. This method also promotes code reuse and reduces the opportunity for user error since relationships only need to be implemented once rather than in every simulation.
