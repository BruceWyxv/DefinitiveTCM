function [scale, power, offset, chiSquared] = FitExponential(x, y)
% Fits data to a gaussian curve
  % Seed the parameters
  linearishY = log(y);
  fit = polyfit(x, linearishY, 2);
  power = fit(1);
  scale = exp(fit(2));
  offset = y(1) - scale * exp(power * x(1));
  
  % Create the evaluation function
  FitEvaluator = @(parameters) CalculateChiSquared(real(log(y)), real(log(parameters(3) + parameters(1) * exp(parameters(2) * x))));
  
  % Fit the data
  options = optimset('MaxFunEvals', 1000);
  [parameters, chiSquared] = fminsearch(FitEvaluator, [scale, power, offset], options);
  scale = parameters(1);
  power = parameters(2);
  offset = parameters(3);
end
