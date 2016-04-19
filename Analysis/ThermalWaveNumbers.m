classdef ThermalWaveNumbers < handle
% ThermalWaveNumbers is the class that is actually used to generate a
% solution to the TCM data
  
  properties (SetAccess = immutable, GetAccess = private)
    absorbedPower; % Fractional absorbed laser power
    absorptionCoefficient; % Absorption coefficient
    fitFunction; % Handle to the function used for fitting
    initialValues; % Initial parameter values
    numberOfFitParameters; % Number of parameters being fitted
    numberOfFrequencies; % Number of frequencies in the data
    numberOfSteps; % Number of steps per frequency
    omegas; % Omega vetor
    preferences; % Global preferences
    settings; % Global settings
  end
  
  properties (SetAccess = immutable, GetAccess = public)
    amplitudeData; % Data amplitude
    fitMask; % Logical matrix identifying which seed parameters to fit, inverse mask (false = reject, true = accept)
    frequencies; % Data frequencies
    isAnisotropic; % Boolean representing the fit type
    phaseData; % Modified data prequencies, max at y = 0
    phaseOffsets; % Offset from original data
    positions; % Modified data positions so phases are centered about x = 0
    positionOffsets; % Offsets from original position vector
    weights; % Weights of the phases
  end
  
  properties (SetAccess = private, GetAccess = private)
    analysisPlot;
  end
  
  properties (SetAccess = private, GetAccess = public)
    analyticalSolution; % The most recent analytic solution data
    chiSquared; % The most recent chi-squared value
    iterations; % The number of iterations the solutions has performed
    values; % The most recent values
  end
  
  methods
    function myself = ThermalWaveNumbers(data,...
                                         fitMask,...
                                         preferences,...
                                         settings,...
                                         initialValues)
    % Create the class
      myself.iterations = 0;
      myself.frequencies = data.frequencies;
      myself.numberOfFrequencies = length(myself.frequencies);
      myself.numberOfSteps = length(data.positions(1,:));
      myself.preferences = preferences;
      myself.settings = settings;
      
      % Assign properties
      myself.fitMask = fitMask;
      myself.initialValues = initialValues;
      myself.numberOfFitParameters = sum(myself.fitMask);
      
      % Preformat the data
      [myself.positions, myself.positionOffsets,...
       myself.phaseData, myself.phaseOffsets,...
       myself.amplitudeData,...
       myself.weights] = ThermalWaveNumbers.Preformatting(data, myself.preferences);
      
      % Precalculate some values
      myself.absorbedPower = 1;
      myself.absorptionCoefficient = 5e9;
      myself.omegas = 2 * pi * frequencies;
      
      % Select the fit function
      myself.isAnisotropic = data.anisotropic;
      if myself.isAnisotropic
        myself.fitFunction = @myself.AnisotropicAnalysisStep;
      else
        myself.fitFunction = @myself.IsotropicAnalysisStep;
      end
    end
    
    function [allProperties, fittedPropertiesMask, chiSquared, fminsearchOutput] = Run(myself)
    % Run an analysis
      startValues = myself.initialValues(myself.fitMask);
      
      % Analyze the data
      fitEvaluation = @(parameters) myself.GoodnessOfFit(myself.fitFunction(parameters));
      problem.objective = fitEvaluation;
      problem.x0 = startValues;
      problem.solver = 'fminsearch';
      problem.options = optimset('OutputFcn', @myself.PlotSearch);
      [finalValues, finalGoodness, exitFlag, output] = fminsearch(problem);
      
      % Return the results
      allProperties = myself.initialValues;
      allProperties(myself.fitMask) = finalValues;
      fittedPropertiesMask = myself.fitMask;
      chiSquared = finalGoodness;
      fminsearchOutput.x = finalValues;
      fminsearchOutput.fval = finalGoodness;
      fminsearchOutput.exitflag = exitFlag;
      fminsearchOutput.output = output;
    end
  end
  
  methods (Access = private)
    function analyticalSolution = AnisotropicAnalysisStep(myself, currentFitValues)
      analyticalSolution = myself + currentFitValues;
    end
    
    function chiSquared = GoodnessOfFit(myself, analyticalSolution)
    % Determines how good the current fitted values are
      chiSquared = 0;
      for f = 1:myself.numberOfFrequencies
        localChiSquared = CalculateChiSquared(myself.phaseData(f,:), analyticalSolution.phases(f,:));
        chiSquared = chiSquared + localChiSquared * myself.weights(f);
      end
      
      degreesOfFreedom = ((myself.numberOfSteps - myself.numberOfFitParameters) * myself.numberOfFrequencies);
      chiSquared = chiSquared / degreesOfFreedom;
    end
    
    function analyticalSolution = IsotropicAnalysisStep(myself, currentFitValues)
    % Performs the isotropic 
      % Set the values of the properties, updating the new values of the
      % properties being fitted
      currentValues = myself.initialValues;
      currentValues(myself.fitMask) = currentFitValues;
      ks = currentValues(FitProperties.SubstrateConductivity);
      Ds = currentValues(FitProperties.SubstrateDiffusivity);
      kf = currentValues(FitProperties.FilmConductivity);
      Df = currentValues(FitProperties.FilmDiffusivity);
      Re = currentValues(FitProperties.SpotSize);
      Rth = currentValues(FitProperties.KapitzaResistance);
      amplitudes = zeros(myself.numberOfFrequencies, myself.numberOfSteps);
      phases = zeros(myself.numberOfFrequencies, myself.numberOfSteps);
      
      % Loop over the frequencies
      for f = 1:myself.numberOfFrequencies
        omega = myself.omegas(f);
        steps = myself.positions(f,:) * 1e-6;

        % Setup p array
        P0 = 1;
        pmax = 10 / (2.0e-6);
        delp = pmax / 1000;
        p = 0:delp:pmax;
        p2 = p.^2;
        pZeros = zeros(1,length(p));
        
        % Parameters from writeup on 3-19-14
        nf = sqrt(p2 + 1i * omega / Df);
        ns = sqrt(p2 + 1i * omega / Ds);
        ksns = ks * ns;
        kfnf = kf * nf;
        rsp1 = Rth * ksns + 1;
        exp2NfDf = exp(-2 * nf * df);
        denominator = (nf .* ((kfnf .* (exp2NfDf - 1) .* rsp1) - (exp2NfDf  + 1) .* ksns));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        F = P0 * myself.absorptionCoefficient * exp(-p2 * Re^2 ...
/ ...                                                     ----
                                                           4) ...
/ ...       --------------------------------------------------
                   (2 * pi * kf);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        E =                        F ...
./ ...      -------------------------------------------------
            (myself.absorptionCoefficient^2 - p2 - 1i * omega ...
/ ...                                                   -----
                                                         Df);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        expDfAlphaNf = exp(-df * (myself.absorptionCoefficient + nf));
        A = -E .* (myself.absorptionCoefficient * (kfnf .* (expDfAlphaNf + 1) .* rsp1 - ksns) - ks * expDfAlphaNf .* ksns) ...
./ ...      -------------------------------------------------------------------------------------------------------------
                                                      denominator;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        expAlphaDf = exp(-myself.absorptionCoefficient * df);
        expDfNf = exp(-nf * df);
        B = -E * (myself.absorptionCoefficient * (kfnf .* (expAlphaDf - expDfNf) .* rsp1 + ksns .* expDfNf) - nf .* expAlphaDf .* ksns) .* expDfNf ...
./ ...      --------------------------------------------------------------------------------------------------------------------------------
                                                                  denominator;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        int = p .* (A + B + E);
  
        % Thermal wave solution
        absSteps = abs(steps);
        integrand = besselj(0, p * absSteps) .* int;
        solution = -trapz(integrand, 2)' * delp;
        phases(f,:) = angle(solution);

        if myself.frequencies(f) <= myself.settings.current.Analysis.frequencyOffsetLimit;
          % Y = 0 offset solution
          integrand0 = besselj(0, pZeros) .* int;
          solution0 = -trapz(integrand0) * delp;
          phaseAt0 = angle(solution0);

          % Account for phase jumps of pi
          phaseOffset = round(abs(phaseAt0 - max(phases(f,:))) / pi);
          phaseAt0 = phaseAt0 + pi * phaseOffset;

          phases(f,:) = phases(f,:) - phaseAt0;
        end

        amplitudes(f,:) = abs(solution) / max(abs(solution));
      end
      
      % Scale to degrees
      phases = rad2deg(phases);
      
      % Increment the iteration counter
      myself.iterations = myself.iterations + 1;
      analyticalSolution.positions = myself.Positions;
      analyticalSolution.amplitudes = amplitudes;
      analyticalSolution.phases = phases;
      myself.analyticalSolution = analyticalSolution;
    end
    
    function halt = PlotSearch(myself, iterations, goodnessValues, state)
    % Plots the progress of the minimization
      halt = false;
      
      switch state
        case 'init'
          % Create the plots
          data.amplitudes = myself.amplitudeData;
          data.phases = myself.phaseData;
          data.positions = myself.positions;
          myself.analysisPlot = Analyze('Data', data,...
                                        'Preferences', myself.preferences,...
                                        'Settings', myself.settings);
          
        case 'iter'
          % Update the plots
          halt = myself.analysisPlot('Update', guidata(myself.analysisPlot), myself, iterations, goodnessValues);
          
        case 'interrupt'
          % Something bad happened, try to figure out what
          halt = true;
          
        case 'done'
          % Minimization has completed, finish up
          myself.analysisPlot('Finalize', guidata(myself.analysisPlot), myself, iterations, goodnessValues);
      end
    end
  end
  
  methods (Static)
    function [positions, positionOffsets,...
              phases, phaseOffsets,...
              amplitudes,...
              weights] = Preformatting(data, preferences)
    % Preformats all the data so that the curves are centered about x=0 and
    % offset so that the peak is at y=0
      numberOfPositions = length(data.positions);
      numberOfFrequencies = length(data.frequencies);
      
      % Scale the data so that the positions reflect the actual distances
      actualPositions = data.positions * preferences.current.Analysis.scanScaling;
      
      % We will evaluate only the central portion
      third = numberOfPositions / 3.0;
      window = [actualPositions(ceiling(third)), floor(actualPositions(floor(third)))];
      fineStep = (window(2) - window(1)) / 500;
      finePositions = window(1):fineStep:window(2);
      
      % We will evaluate each position/amplitude/phase set individually
      amplitudes = zeros(numberOfFrequencies, numberOfPositions);
      phaseOffsets = zeros(1, numberOfFrequencies);
      positionOffsets = zeros(1, numberOfFrequencies);
      phases = zeros(numberOfFrequencies, numberOfPositions);
      positions = zeros(numberOfFrequencies, numberOfPositions);
      
      % Loop over all the frequencies
      for f = 1:numberOfFrequencies
        % Evaluate the phase and position offsets
        polys = polyfit(actualPositions(window(1):window(2)), data.phases(f,window(1):window(2)), 2);
        evaluatedFit = polyval(polys, finePositions);
        [phaseOffsets(f), index] = max(evaluatedFit);
        positionOffsets(f) = finePositions(index);
        phases(f,:) = data.phases(f,:) - phaseOffsets(f);
        positions(f,:) = actualPositions - positionOffsets(f);
        
        % Normalize the amplitudes
        [mu, sigma, scale] = FitGaussian(actualPositions(window(1):window(2)), data.amplitudes(f,window(1):window(2)) - min(data.amplitudes(f,:)));
        evaluatedFit = gaussian(finePositions, mu, sigma, scale) + min(data.amplitudes(f,:));
        amplitudes(f,:) = data.amplitudes(f,:) / max(evaluatedFit);
      end
      
      % Calculate the weights
      if preferences.current.Analysis.weightFrequencies == 1
        weights(f) = 1.0 / min(phases(f,:));
      else
        weights = ones(1, numberOfFrequencies) ./ min(min(phases));
      end
      weights = abs(weights);
    end
  end
end

