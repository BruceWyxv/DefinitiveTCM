classdef ThermalWaveNumbers
% ThermalWaveNumbers is the class that is actually used to generate a
% solution to the TCM data
  
  properties (SetAccess = immutable, GetAccess = private)
    absorbedPower; % Fractional absorbed laser power
    absorptionCoefficient; % Absorption coefficient
    amplitudes; % Data amplitude
    fitParameters; % Logical matrix identifying which seed parameters to fit
    frequencies; % Data frequencies
    omegas; % Omega vetor
    parameterNames; % Names of the parameters
    parameterInitialValues; % Initial parameter values
    phases; % Modified data prequencies, max at y = 0
    phaseOffsets; % Offset from original data
    positions; % Modified data positions so phases are centered about x = 0
    positionOffsets; % Offsets from original position vector
    weights; % Weights of the phases
  end
  
  properties (Constant, GetAccess = public)
    substrateConductivityIndex = 1;
    substrateDiffusivityIndex = 2;
    substrateConductivity2Index = 3;
    substrateDiffusivity2Index = 4;
    filmConductivityIndex = 5;
    filmDiffusivityIndex = 6;
    kapitzaResistanceIndex = 7;
    spotSizeIndex = 8;
  end
  
  methods
    function myself = ThermalWaveNumbers(data,...
                                         fitParameters,...
                                         preferences,...
                                         parameterInitialValues, parameterNames)
    % Create the class and initialize the permanent data members
      % Assign properties
      myself.fitParameters = fitParameters;
      myself.parameterInitialValues = parameterInitialValues;
      myself.parameterNames = parameterNames;
      
      % Preformat the data
      [myself.positions, myself.positionOffsets,...
       myself.phases, myself.phaseOffsets,...
       myself.amplitudes,...
       myself.weights] = Preformatting(data, preferences);
      
      % Precalculate some values
      myself.absorbedPower = 1;
      myself.absorptionCoefficient = 5e9;
      myself.omegas = 2 * pi * frequencies;
    end
    
    function results = Run()
    % Run an analysis
    end
  end
  
  methods (Access = private)
    function analyticalData = AnalysisStep(myself, currentValues)
    % Performs the actual calculation of the analytical result
    end
  end
end

