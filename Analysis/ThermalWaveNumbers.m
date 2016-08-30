classdef ThermalWaveNumbers < handle
% ThermalWaveNumbers is the class that is actually used to generate a
% solution to the TCM data
  
  properties (SetAccess = immutable, GetAccess = private)
    absorbedPower; % Fractional absorbed laser power
    absorptionCoefficient; % Absorption coefficient
    fitFunction; % Handle to the function used for fitting
    frequencyOffsetLimit; % Maximum frequency to apply an offset to
    integrationSteps; % Integrations steps during fitting
    integrationWidth; % Phase space width during fitting
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
    interrupted; % True if the analysis process was interrupted
    comparison;
  end
  
  properties (SetAccess = private, GetAccess = public)
    analyticalSolution; % The most recent analytic solution data
    chiSquared; % The most recent chi-squared value
    currentValues; % The most current values
    elapsedTime; % Amount of time spent in the analysis
    iterations; % The number of iterations the solutions has performed
    previousValues; % The values from th previous iteration
    timer; % A timer user to measure the duration of an analysis
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
      myself.interrupted = false;
      myself.numberOfFrequencies = length(myself.frequencies);
      myself.numberOfSteps = length(data.positions(1,:));
      myself.preferences = preferences;
      myself.settings = settings;
      
      % Cache frequently used settings
      myself.frequencyOffsetLimit = settings.current.Analysis.frequencyOffsetLimit;
      myself.integrationSteps = settings.current.Analysis.integrationSteps;
      myself.integrationWidth = settings.current.Analysis.integrationWidth;
      
      % Assign properties
      myself.fitMask = fitMask;
      myself.amplitudeWeight = amplitudeWeight;
      myself.initialValues = initialValues;
      myself.numberOfFitParameters = sum(myself.fitMask);
      
      % Preformat the data
      [myself.positions, myself.positionOffsets,...
       myself.phaseData, myself.phaseOffsets,...
       myself.amplitudeData,...
       myself.weights] = ThermalWaveNumbers.Preformatting(data, myself.preferences, myself.settings);
      
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
    
    function standardError = GetStandardError(myself)
    % Calculate the standard error of the final solution
      if myself.settings.current.Analysis.skipErrorAnalysis || myself.interrupted
        standardError = -ones(1, myself.numberOfFrequencies);
      else
        % standard deviation of the residuals
        if myself.amplitudeWeight > 0
          degreesOfFreedom = myself.numberOfFrequencies * (myself.numberOfSteps + length(myself.amplitudeData(1,:)) - 2);
        else
          degreesOfFreedom = myself.numberOfFrequencies * (myself.numberOfSteps - 2);
        end
        identityWeights = ones(1, myself.numberOfFrequencies);
        sdr2 = myself.GoodnessOfFit(myself.analyticalSolution, identityWeights) / degreesOfFreedom;

        % jacobian matrix
        J = ThermalWaveNumbers.JacobianEstimation(myself.fitFunction, myself.currentValues(myself.fitMask));

        % I'll be lazy here, and use inv. Please, no flames,
        % if you want a better approach, look in my tips and
        % tricks doc.
        Sigma2 = sdr2*inv(J'*J);

        % Parameter standard errors
        se2 = sqrt(diag(Sigma2))';

        % which suggest rough confidence intervalues around
        % the parameters might be...
        standardError = 2 * se2;
      end
    end
    
    function [allProperties, fittedPropertiesMask, chiSquared, fminsearchOutput] = Run(myself)
    % Run an analysis
      startValues = myself.initialValues(myself.fitMask);
      
      % Analyze the data
      fitEvaluation = @(parameters) myself.GoodnessOfFit(myself.fitFunction(parameters), myself.weights);
      problem.objective = fitEvaluation;
      problem.x0 = startValues;
      problem.solver = 'fminsearch';
      problem.options = optimset('MaxFunEvals', myself.settings.current.Analysis.maximumEvaluations,...
                                 'MaxIter', myself.settings.current.Analysis.maximumEvaluations,...
                                 'OutputFcn', @myself.MinimizationPlot,...
                                 'TolFun', myself.settings.current.Analysis.tolerance,...
                                 'TolX', myself.settings.current.Analysis.tolerance);
      global dtcmchihistory;
      dtcmchihistory = [];
      [finalValues, finalGoodness, exitFlag, output] = fminsearch(problem);
      
      % Return the results
      comparison = myself.comparison;
      save('S:\Matlab\comp_suite.mat', 'comparison');
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
    
    function FinalizeAnalysisPlot(myself, success, showMessage)
    % Closes the analysis plot window
      AnalysisProgress('Finalize', myself.analysisPlot, guidata(myself.analysisPlot), myself, success, showMessage);
    end
    
    function chiSquared = GoodnessOfFit(myself, analyticalSolution, weights)
    % Determines how good the current fitted values are
    global dtcmchihistory;
      chiSquared = 0;
      for f = 1:myself.numberOfFrequencies
        phaseChiSquared = CalculateChiSquared(myself.phaseData(f,:), analyticalSolution.phases(f,:));
        if myself.amplitudeWeight > 0
          amplitudeChiSquared = CalculateChiSquared(myself.amplitudeData(f,:), analyticalSolution.amplitudes(f,:));
          %phaseScale = abs(max(analyticalSolution.phases(f,:)) - min(analyticalSolution.phases(f,:)));
          %amplitudeChiSquared = amplitudeChiSquared * phaseScale * myself.amplitudeWeight;
        else
          amplitudeChiSquared = 0;
        end
        chiSquared = chiSquared + ((phaseChiSquared + amplitudeChiSquared) * weights(f));
      end
      
      degreesOfFreedom = myself.numberOfFitParameters - 1;
      %chiSquared = chiSquared / degreesOfFreedom;
      myself.chiSquared = chiSquared;
      dtcmchihistory = [dtcmchihistory chiSquared];
    end

    function analyticalSolution = IsotropicAnalysisStep(myself, currentFitValues)
    % Performs an isotropic step
      % Set the values of the properties, updating the new values of the
      % properties being fitted
      myself.previousValues = myself.currentValues;
      myself.currentValues = myself.initialValues;
      myself.currentValues(myself.fitMask) = currentFitValues;
      alphaf = myself.absorptionCoefficient;
      ks = myself.currentValues(FitProperties.SubstrateConductivity);
      Ds = myself.currentValues(FitProperties.SubstrateDiffusivity);
      kf = myself.currentValues(FitProperties.FilmConductivity);
      Df = myself.currentValues(FitProperties.FilmDiffusivity);
      h = myself.filmThickness;
      Re = myself.currentValues(FitProperties.SpotSize);
      Rth = myself.currentValues(FitProperties.KapitzaResistance);
      amplitudes = zeros(myself.numberOfFrequencies, myself.numberOfSteps);
      phases = zeros(myself.numberOfFrequencies, myself.numberOfSteps);

      % Loop over the frequencies
      for f = 1:myself.numberOfFrequencies
        omega = myself.omegas(f);
        steps = myself.positions(f,:) * 1e-6;

        % Setup p array
        P0 = 1;
        pmax = myself.integrationWidth;
        delp = pmax / myself.integrationSteps;
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

        if myself.frequencies(f) <= myself.frequencyOffsetLimit
          % Get value at y=0 for offset calculation
          integrand0 = besselj(0, 0) * int;
          T0 = -trapz(integrand0) * delp;
          offsetAngle = angle(T0);
        else
          offsetAngle = 0;
        end

        % Account for phase jumps of PI
        delta = round(abs(offsetAngle - max(phases(f,:))) / pi);
        offsetAngle = offsetAngle + pi * delta;
        phases(f,:) = phases(f,:) - offsetAngle;
        amplitudes(f,:) = abs(solution) / max(abs(solution));
        phaseMod = rad2deg(phases(f,:));
        comparisons = [phaseMod, amplitudes(f,:)]';
        if ~exist('comparisonAll', 'var')
          comparisonAll = comparisons;
        else
          comparisonAll = [comparisonAll; comparisons];
        end
      end

      % Scale to degrees
      phases = rad2deg(phases);

      % Increment the iteration counter
      myself.iterations = myself.iterations + 1;
      analyticalSolution.positions = myself.positions;
      analyticalSolution.amplitudes = amplitudes;
      analyticalSolution.phases = phases;
      myself.analyticalSolution = analyticalSolution;
      myself.comparison = [myself.comparison, comparisonAll];
      %myself.comparison = [myself.comparison; currentFitValues];
    end

    function halt = MinimizationPlot(myself, goodness, stepInformation, state) %#ok<INUSL>
    % Plots the progress of the minimization
      halt = false;

      switch state
        case 'init'
          % Create the plots
          myself.timer = tic;
          data.amplitudes = myself.amplitudeData;
          data.frequencies = myself.frequencies;
          data.phases = myself.phaseData;
          data.positions = myself.positions;
          myself.analysisPlot = AnalysisProgress('Data', data,...
                                                 'Preferences', myself.preferences,...
                                                 'Settings', myself.settings);

        case 'iter'
          % Calculate the current elapsed time
          myself.elapsedTime = toc(myself.timer);

          % Update the plots
          halt = AnalysisProgress('Update', guidata(myself.analysisPlot), myself);
          if halt
            FinalizeAnalysisPlot(myself, false, false)
          end

        case 'interrupt'
          % Update the plots
          halt = AnalysisProgress('Update', guidata(myself.analysisPlot), myself);
          if halt
            FinalizeAnalysisPlot(myself, false, false)
          end

        case 'done'
          % Calculate the total elapsed time
          myself.elapsedTime = toc(myself.timer);

          % Minimization has completed, finish up
          FinalizeAnalysisPlot(myself, true, true)
      end
      
      myself.interrupted = halt;
    end
  end

  methods (Static)
    function [jac,err] = JacobianEstimation(fun, x0)
    % gradest: estimate of the Jacobian matrix of a vector valued function of n variables
    % usage: [jac,err] = jacobianest(fun,x0)
    %
    % 
    % arguments: (input)
    %  fun - (vector valued) analytical function to differentiate.
    %        fun must be a function of the vector or array x0.
    % 
    %  x0  - vector location at which to differentiate fun
    %        If x0 is an nxm array, then fun is assumed to be
    %        a function of n*m variables.
    %
    %
    % arguments: (output)
    %  jac - array of first partial derivatives of fun.
    %        Assuming that x0 is a vector of length p
    %        and fun returns a vector of length n, then
    %        jac will be an array of size (n,p)
    %
    %  err - vector of error estimates corresponding to
    %        each partial derivative in jac.
    %
    %
    % Example: (nonlinear least squares)
    %  xdata = (0:.1:1)';
    %  ydata = 1+2*exp(0.75*xdata);
    %  fun = @(c) ((c(1)+c(2)*exp(c(3)*xdata)) - ydata).^2;
    %
    %  [jac,err] = jacobianest(fun,[1 1 1])
    %
    %  jac =
    %           -2           -2            0
    %      -2.1012      -2.3222     -0.23222
    %      -2.2045      -2.6926     -0.53852
    %      -2.3096      -3.1176     -0.93528
    %      -2.4158      -3.6039      -1.4416
    %      -2.5225      -4.1589      -2.0795
    %       -2.629      -4.7904      -2.8742
    %      -2.7343      -5.5063      -3.8544
    %      -2.8374      -6.3147      -5.0518
    %      -2.9369      -7.2237      -6.5013
    %      -3.0314      -8.2403      -8.2403
    %
    %  err =
    %   5.0134e-15   5.0134e-15            0
    %   5.0134e-15            0   2.8211e-14
    %   5.0134e-15   8.6834e-15   1.5804e-14
    %            0     7.09e-15   3.8227e-13
    %   5.0134e-15   5.0134e-15   7.5201e-15
    %   5.0134e-15   1.0027e-14   2.9233e-14
    %   5.0134e-15            0   6.0585e-13
    %   5.0134e-15   1.0027e-14   7.2673e-13
    %   5.0134e-15   1.0027e-14   3.0495e-13
    %   5.0134e-15   1.0027e-14   3.1707e-14
    %   5.0134e-15   2.0053e-14   1.4013e-12
    %
    %  (At [1 2 0.75], jac should be numerically zero)
    %
    %
    % See also: derivest, gradient, gradest
    %
    %
    % Author: John D'Errico
    % e-mail: woodchips@rochester.rr.com
    % Release: 1.0
    % Release date: 3/6/2007

      % get the length of x0 for the size of jac
      nx = numel(x0);

      MaxStep = 100;
      StepRatio = 2.0000001;

      % was a string supplied?
      if ischar(fun)
        fun = str2func(fun);
      end

      % get fun at the center point
      f0 = fun(x0);
      f0 = f0.phases(:);
      n = length(f0);
      if n==0
        % empty begets empty
        jac = zeros(0,nx);
        err = jac;
        return
      end

      relativedelta = MaxStep*StepRatio .^(0:-1:-25);
      nsteps = length(relativedelta);

      % total number of derivatives we will need to take
      jac = zeros(n,nx);
      err = jac;
      for i = 1:nx
        x0_i = x0(i);
        if x0_i ~= 0
          delta = x0_i*relativedelta;
        else
          delta = relativedelta;
        end

        % evaluate at each step, centered around x0_i
        % difference to give a second order estimate
        fdel = zeros(n,nsteps);
        for j = 1:nsteps
          plusDiff = fun(ThermalWaveNumbers.swapelement(x0,i,x0_i + delta(j)));
          minusDiff = fun(ThermalWaveNumbers.swapelement(x0,i,x0_i - delta(j)));
          fdif = plusDiff.phases(:) - minusDiff.phases(:);

          fdel(:,j) = fdif(:);
        end

        % these are pure second order estimates of the
        % first derivative, for each trial delta.
        derest = fdel.*repmat(0.5 ./ delta,n,1);

        % The error term on these estimates has a second order
        % component, but also some 4th and 6th order terms in it.
        % Use Romberg exrapolation to improve the estimates to
        % 6th order, as well as to provide the error estimate.

        % loop here, as rombextrap coupled with the trimming
        % will get complicated otherwise.
        for j = 1:n
          [der_romb,errest] = ThermalWaveNumbers.rombextrap(StepRatio,derest(j,:),[2 4]);

          % trim off 3 estimates at each end of the scale
          nest = length(der_romb);
          trim = [1:3, nest+(-2:0)];
          [der_romb,tags] = sort(der_romb);
          der_romb(trim) = [];
          tags(trim) = [];

          errest = errest(tags);

          % now pick the estimate with the lowest predicted error
          [err(j,i),ind] = min(errest);
          jac(j,i) = der_romb(ind);
        end
      end
    end % mainline function end
    
    function [positions, positionOffsets,...
              phases, phaseOffsets,...
              amplitudes,...
              weights] = Preformatting(data, preferences, settings)
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
      weights = ones(1, numberOfFrequencies);

      % Loop over all the frequencies
      for f = 1:numberOfFrequencies
        % Evaluate the phase and position offsets
        polys = polyfit(actualPositions(window(1):window(2)), data.phases(f,window(1):window(2)), 2);
        evaluatedFit = polyval(polys, finePositions);
        [phaseOffsets(f), index] = max(evaluatedFit);
        if data.frequencies(f) > settings.current.Analysis.frequencyOffsetLimit
          phaseOffsets(f) = 0;
        end
        positionOffsets(f) = finePositions(index);
        phases(f,:) = data.phases(f,:) - phaseOffsets(f);
        positions(f,:) = actualPositions - positionOffsets(f);

        % Normalize the amplitudes
        amplitudes(f,:) = data.amplitudes(f,:) / max(data.amplitudes(f,:));

        % Calculate the weights
        if preferences.current.Analysis.weightFrequencies == 1
          weights(f) = (1.0 / min(phases(f,:)))^2;
        end
      end
    end

    
    function vec = swapelement(vec,ind,val)
    % swaps val as element ind, into the vector vec
      vec(ind) = val;
    end
    
    
    function [der_romb,errest] = rombextrap(StepRatio,der_init,rombexpon)
    % do romberg extrapolation for each estimate
    %
    %  StepRatio - Ratio decrease in step
    %  der_init - initial derivative estimates
    %  rombexpon - higher order terms to cancel using the romberg step
    %
    %  der_romb - derivative estimates returned
    %  errest - error estimates
    %  amp - noise amplification factor due to the romberg step

    srinv = 1/StepRatio;

    % do nothing if no romberg terms
    nexpon = length(rombexpon);
    rmat = ones(nexpon+2,nexpon+1);
    % two romberg terms
    rmat(2,2:3) = srinv.^rombexpon;
    rmat(3,2:3) = srinv.^(2*rombexpon);
    rmat(4,2:3) = srinv.^(3*rombexpon);

    % qr factorization used for the extrapolation as well
    % as the uncertainty estimates
    [qromb,rromb] = qr(rmat,0);

    % the noise amplification is further amplified by the Romberg step.
    % amp = cond(rromb);

    % this does the extrapolation to a zero step size.
    ne = length(der_init);
    rhs = ThermalWaveNumbers.vec2mat(der_init,nexpon+2,ne - (nexpon+2));
    rombcoefs = rromb\(qromb'*rhs);
    der_romb = rombcoefs(1,:)';

    % uncertainty estimate of derivative prediction
    s = sqrt(sum((rhs - rmat*rombcoefs).^2,1));
    rinv = rromb\eye(nexpon+1);
    cov1 = sum(rinv.^2,2); % 1 spare dof
    errest = s'*12.7062047361747*sqrt(cov1(1));

    end % rombextrap
    
    
    function mat = vec2mat(vec,n,m)
    % forms the matrix M, such that M(i,j) = vec(i+j-1)
    [i,j] = ndgrid(1:n,0:m-1);
    ind = i+j;
    mat = vec(ind);
    if n==1
      mat = mat';
    end

    end % vec2mat
  end
end

