function value = CalculateChiSquared(data, fit)
% Returns the chi squared value of a data set and the fit
  value = sum((data - fit).^2);
end
