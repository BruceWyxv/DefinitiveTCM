function value = gaussian(x, mu, sigma, scale)
% Computes the value of x at a point on a normalized gaussian pdf
  if nargin < 4
    scale = 1.0;
  end
  norm = 1 / (sigma * sqrt(2 * pi)) * scale;
  exponent = (x - mu).^2 ./ (2 * sigma * sigma); 
  value = norm * exp(-exponent);
end
