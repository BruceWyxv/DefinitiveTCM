function [mu, sigma, scale, chiSquared] = FitGaussian(x, y)
% Fits data to a gaussian curve
  % Seed the parameters
  [~, index] = max(y);
  mu = x(index);
  scale =  trapz(x, y);
  scaledY = y / scale;
  
  % Create the evaluation function
  FitEvaluator = @(parameters) CalculateChiSquared(scaledY, gaussian(x, parameters(1), parameters(2)));
  
  % Fit the data
  [parameters, chiSquared] = fminsearch(FitEvaluator, [mu, 1]);
  mu = parameters(1);
  sigma = parameters(2);
end

function value = CalculateChiSquared(data, fit)
% Returns the chi squared value of a data set and the fit
  value = sum((data - fit).^2);
end

