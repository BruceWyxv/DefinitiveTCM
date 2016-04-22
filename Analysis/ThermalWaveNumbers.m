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
      df = myself.filmThickness;
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
%         p2 = p.^2;
        pZeros = zeros(1,length(p));
        
        % Parameters from writeup on 3-19-14
        nf=sqrt(p.^2+1i*omega/Df);
        ns=sqrt(p.^2+1i*omega/Ds);
        F=P0*alphaf*exp(-p.^2*Re^2/4)/(2*pi*kf);
        E=F./(alphaf^2-p.^2-1i*omega/Df);
        A=-E.*(-alphaf.*kf.*nf-alphaf.*kf.*ns.*ks.*Rth.*nf-alphaf.*ns.*ks+alphaf.*kf.*exp(-alphaf.*df-nf.*df).*nf-exp(-alphaf.*df-nf.*df).*nf.*ns.*ks+exp(-alphaf.*df-nf.*df).*nf.*kf.*ns.*ks.*Rth.*alphaf)./nf./(-nf.*kf-nf.*kf.*ns.*ks.*Rth-ns.*ks+nf.*kf.*exp(-2.*nf.*df)+nf.*kf.*ns.*ks.*Rth.*exp(-2.*nf.*df)-ns.*ks.*exp(-2.*nf.*df));
        B=-E.*(alphaf.*kf.*exp(-alphaf.*df).*nf-exp(-alphaf.*df).*nf.*ns.*ks+exp(-alphaf.*df).*nf.*kf.*ns.*ks.*Rth.*alphaf-nf.*kf.*exp(-nf.*df).*alphaf-alphaf.*kf.*ns.*ks.*Rth.*exp(-nf.*df).*nf+alphaf.*ns.*ks.*exp(-nf.*df)).*exp(-nf.*df)./nf./(-nf.*kf-nf.*kf.*ns.*ks.*Rth-ns.*ks+nf.*kf.*exp(-2.*nf.*df)+nf.*kf.*ns.*ks.*Rth.*exp(-2.*nf.*df)-ns.*ks.*exp(-2.*nf.*df));
        int=p.*(A+B+E);
%         nf = sqrt(p2 + 1i * omega / Df);
%         ns = sqrt(p2 + 1i * omega / Ds);
%         ksns = ks * ns;
%         kfnf = kf * nf;
%         rsp1 = Rth * ksns + 1;
%         exp2NfDf = exp(-2 * nf * Df);
%         denominator = (nf .* ((kfnf .* (exp2NfDf - 1) .* rsp1) - (exp2NfDf  + 1) .* ksns));
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         F = P0 * myself.absorptionCoefficient * exp(-p2 * Re^2 ...
% / ...                                                     ----
%                                                            4) ...
% / ...       --------------------------------------------------
%                    (2 * pi * kf);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         E =                        F ...
% ./ ...      -------------------------------------------------
%             (myself.absorptionCoefficient^2 - p2 - 1i * omega ...
% / ...                                                   -----
%                                                          Df);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         expDfAlphaNf = exp(-Df * (myself.absorptionCoefficient + nf));
%         A = -E .* (myself.absorptionCoefficient * (kfnf .* (expDfAlphaNf + 1) .* rsp1 - ksns) - ks * expDfAlphaNf .* ksns) ...
% ./ ...      -------------------------------------------------------------------------------------------------------------
%                                                       denominator;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         expAlphaDf = exp(-myself.absorptionCoefficient * Df);
%         expDfNf = exp(-nf * Df);
%         B = -E .* (myself.absorptionCoefficient * (kfnf .* (expAlphaDf - expDfNf) .* rsp1 + ksns .* expDfNf) - nf .* expAlphaDf .* ksns) .* expDfNf ...
% ./ ...      --------------------------------------------------------------------------------------------------------------------------------
%                                                                   denominator;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         int = p .* (A + B + E);
  
%         % Thermal wave solution
%         absSteps = abs(steps);
%         integrand = bsxfun(@times, besselj(0, absSteps' * p), int);
%         solution = -trapz(integrand, 2)' * delp;
%         phases(f,:) = angle(solution);

%         % Y = 0 offset
%         middle = ceil(myself.numberOfSteps / 2);
%         phaseOffset = phases(f,middle);
%         phases(f,:) = phases(f,:) - phaseOffset;

        solution = zeros(1, myself.numberOfSteps);
        for i = 1:myself.numberOfSteps
          y = abs(steps(i));
          integrand = besselj(0, p * y) .* int;
          solution(i) = -trapz(integrand) * delp;
        end
        phases(f,:) = angle(solution);
        
        % get value at y=0 for offset calculation
        integrand0 = besselj(0, 0) * int;
        T0 = -trapz(integrand0) * delp;
        offsetAngle = angle(T0);

        % Get the phases
        
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

