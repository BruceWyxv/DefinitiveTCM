classdef ThermalWaveNumbers < handle
% ThermalWaveNumbers is the class that is actually used to generate a
% solution to the TCM data
  
  properties (SetAccess = immutable, GetAccess = private)
    absorbedPower; % Fractional absorbed laser power
    absorptionCoefficient; % Absorption coefficient
    fitFunction; % Handle to the function used for fitting
    numberOfFitParameters; % Number of parameters being fitted
    numberOfFrequencies; % Number of frequencies in the data
    numberOfSteps; % Number of steps per frequency
    omegas; % Omega vetor
    preferences; % Global preferences
    settings; % Global settings
  end
  
  properties (SetAccess = immutable, GetAccess = public)
    amplitudeData; % Data amplitude
    amplitudeWeight; % Fractional weight applied when fitting the amplitude
    filmThickness; % Film thickness, in m
    fitMask; % Logical matrix identifying which seed parameters to fit, inverse mask (false = reject, true = accept)
    frequencies; % Data frequencies
    initialValues; % Initial parameter values
    isAnisotropic; % Boolean representing the fit type
    phaseData; % Modified data prequencies, max at y = 0
    phaseOffsets; % Offset from original data
    positions; % Modified data positions so phases are centered about x = 0
    positionOffsets; % Offsets from original position vector
    weights; % Weights of the phases
  end
  
  properties (SetAccess = private, GetAccess = private)
    analysisPlot; % A handle to a window that plots the intermediate values
  end
  
  properties (SetAccess = private, GetAccess = public)
    analyticalSolution; % The most recent analytic solution data
    chiSquared; % The most recent chi-squared value
    elapsedTime; % Amount of time spent in the analysis
    iterations; % The number of iterations the solutions has performed
    timer; % A timer user to measure the duration of an analysis
    values; % The most recent values
  end
  
  methods
    function myself = ThermalWaveNumbers(data,...
                                         filmThickness,...
                                         amplitudeWeight,...
                                         fitMask,...
                                         preferences,...
                                         settings,...
                                         initialValues)
    % Create the class
      myself.iterations = 0;
      myself.filmThickness = filmThickness;
      myself.frequencies = data.frequencies;
      myself.numberOfFrequencies = length(myself.frequencies);
      myself.numberOfSteps = length(data.positions(1,:));
      myself.preferences = preferences;
      myself.settings = settings;
      
      % Assign properties
      myself.fitMask = fitMask;
      myself.amplitudeWeight = amplitudeWeight;
      myself.initialValues = initialValues;
      myself.numberOfFitParameters = sum(myself.fitMask);
      
      % Preformat the data
      [myself.positions, myself.positionOffsets,...
       myself.phaseData, myself.phaseOffsets,...
       myself.amplitudeData,...
       myself.weights] = ThermalWaveNumbers.Preformatting(data, myself.settings);
      
      % Precalculate some values
      myself.absorbedPower = 1;
      myself.absorptionCoefficient = 5e9;
      myself.omegas = 2 * pi * myself.frequencies;
      
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
      problem.options = optimset('OutputFcn', @myself.MinimizationPlot);
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
  
      % Report on the elapsed time
      fprintf('It took %g seconds to analyze the data.\n\n', myself.elapsedTime);
    end
  end
  
  methods (Access = private)
    function analyticalSolution = AnisotropicAnalysisStep(myself, currentFitValues)
      analyticalSolution = myself + currentFitValues;
    end
    
    function CloseAnalysisPlot(myself, goodness, stepInformation, success, showMessage)
    % Closes the analysis plot window
      AnalysisProgress('Finalize', guidata(myself.analysisPlot), myself, goodness, stepInformation, success, showMessage);
      close(myself.analysisPlot);
      delete(myself.analysisPlot);
    end
    
    function chiSquared = GoodnessOfFit(myself, analyticalSolution)
    % Determines how good the current fitted values are
      chiSquared = 0;
      for f = 1:myself.numberOfFrequencies
        phaseChiSquared = CalculateChiSquared(myself.phaseData(f,:), analyticalSolution.phases(f,:));
        if myself.amplitudeWeight > 0
          amplitudeChiSquared = CalculateChiSquared(myself.amplitudeData(f,:), analyticalSolution.amplitudes(f,:));
          phaseScale = abs(max(analyticalSolution.phases(f,:)) - min(analyticalSolution.phases(f,:)));
          amplitudeChiSquared = amplitudeChiSquared * phaseScale * myself.amplitudeWeight;
        else
          amplitudeChiSquared = 0;
        end
        chiSquared = chiSquared + ((phaseChiSquared + amplitudeChiSquared) * myself.weights(f));
      end
      
      degreesOfFreedom = myself.numberOfFitParameters - 1;
      chiSquared = chiSquared / degreesOfFreedom;
      myself.chiSquared = chiSquared;
    end
    
    function analyticalSolution = IsotropicAnalysisStep(myself, currentFitValues)
    % Performs an isotropic step
      % Set the values of the properties, updating the new values of the
      % properties being fitted
      currentValues = myself.initialValues;
      currentValues(myself.fitMask) = currentFitValues;
      alphaf = myself.absorptionCoefficient;
      ks = currentValues(FitProperties.SubstrateConductivity);
      Ds = currentValues(FitProperties.SubstrateDiffusivity);
      kf = currentValues(FitProperties.FilmConductivity);
      Df = currentValues(FitProperties.FilmDiffusivity);
      h = myself.filmThickness;
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
        
        % Parameters from writeup on 3-19-14
        % Condensing the math here adds legibility and reduces compute time
        % by about 5%
        nf = sqrt(p2 + 1i * omega / Df);
        ns = sqrt(p2 + 1i * omega / Ds);
        common1 = exp(-2 * nf * h);
        common2 = exp(-h * (alphaf * nf));
        common3 = exp(-alphaf * h);
        common4 = exp(-nf * h);
        nfkf = nf * kf;
        nsks = ns * ks;
        denominator = nf .* ...
          (- nfkf .* (1 + nsks * Rth ) .* (1 - common1) ...
           - nsks .* (1 + common1));
        F = P0 * alphaf * exp(-p2 * Re^2 / 4)/(2 * pi * kf);
        E = F ./ (alphaf^2 - p2 - 1i * omega / Df);
        A = E .* ...
          (+ alphaf * (+ nfkf .* (1 + nsks * Rth) .* (1 - common2)...
                       + nsks) ...
           + common2 .* nf .* nsks) ...
          ./ denominator;
        B = -E .* common4 .* ...
          (+ alphaf * (+ nfkf .* (common3 - common4) .* (1 + nsks * Rth) ...
                       + nsks .* common4) ...
           - common3 .* nf .* nsks) ...
           ./ denominator;
        int = p .* (A + B + E);

        % Generate the solutions
        % Eliminating the for loop for each step improves performance by
        % about 5%
        measurementPositions = abs(steps)';
        integrand = bsxfun(@times, besselj(0, measurementPositions * p), int);
        solution = -trapz(integrand, 2) * delp;
        phases(f,:) = angle(solution);
        
        % Get value at y=0 for offset calculation
        integrand0 = besselj(0, 0) * int;
        T0 = -trapz(integrand0) * delp;
        offsetAngle = angle(T0);
        
        % Account for phase jumps of PI
        delta = round(abs(offsetAngle - max(phases(f,:))) / pi);
        offsetAngle = offsetAngle + pi * delta;
        phases(f,:) = phases(f,:) - offsetAngle;
        amplitudes(f,:) = abs(solution) / max(abs(solution));
      end
      
      % Scale to degrees
      phases = rad2deg(phases);
      
      % Increment the iteration counter
      myself.iterations = myself.iterations + 1;
      analyticalSolution.positions = myself.positions;
      analyticalSolution.amplitudes = amplitudes;
      analyticalSolution.phases = phases;
      myself.analyticalSolution = analyticalSolution;
    end
    
    function halt = MinimizationPlot(myself, goodness, stepInformation, state)
    % Plots the progress of the minimization
      halt = false;
      
      switch state
        case 'init'
          % Create the plots
          myself.timer = tic;
          data.amplitudes = myself.amplitudeData;
          data.phases = myself.phaseData;
          data.positions = myself.positions;
          myself.analysisPlot = AnalysisProgress('Data', data,...
                                                 'Preferences', myself.preferences,...
                                                 'Settings', myself.settings);
          
        case 'iter'
          % Update the plots
          halt = AnalysisProgress('Update', guidata(myself.analysisPlot), myself, goodness, stepInformation);
          if halt
            CloseAnalysisPlot(myself, goodness, stepInformation, false, false)
          end
          
        case 'interrupt'
          % Update the plots
          halt = AnalysisProgress('Update', guidata(myself.analysisPlot), myself, goodness, stepInformation);
          if halt
            CloseAnalysisPlot(myself, goodness, stepInformation, false, false)
          end
          
        case 'done'
          % Minimization has completed, finish up
          myself.elapsedTime = toc(myself.timer);
          CloseAnalysisPlot(myself, goodness, stepInformation, true, true)
      end
    end
  end
  
  methods (Static)
    function [positions, positionOffsets,...
              phases, phaseOffsets,...
              amplitudes,...
              weights] = Preformatting(data, settings)
    % Preformats all the data so that the curves are centered about x=0 and
    % offset so that the peak is at y=0
      numberOfSteps = length(data.positions);
      numberOfFrequencies = length(data.frequencies);
      
      % Scale the data so that the positions reflect the actual distances
      actualPositions = data.positions * settings.current.Analysis.scanScaling;
      
      % We will evaluate only the central portion
      middle = round(numberOfSteps / 2);
      window = [(middle - 4), (middle + 4)];
%       third = numberOfSteps / 3.0;
%       window = uint8([ceil(third), floor(2 * third)]);
      fineStep = (actualPositions(window(2)) - actualPositions(window(1))) / 100;
      finePositions = actualPositions(window(1)):fineStep:actualPositions(window(2));
      
      % We will evaluate each position/amplitude/phase set individually
      amplitudes = zeros(numberOfFrequencies, numberOfSteps);
      phaseOffsets = zeros(1, numberOfFrequencies);
      positionOffsets = zeros(1, numberOfFrequencies);
      phases = zeros(numberOfFrequencies, numberOfSteps);
      positions = zeros(numberOfFrequencies, numberOfSteps);
      weights = zeros(1, numberOfFrequencies);
      
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
      
        % Calculate the weights
        if settings.current.Analysis.weightFrequencies == 1
          weights(f) = sqrt(abs(1.0 / min(phases(f,:))));
        end
      end
    end
  end
end

