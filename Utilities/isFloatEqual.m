function isEqual = isFloatEqual(floatA, floatB, tolerance)
% Compares two floating point values to see if they are equal within the
% specified tolerance
  if abs(floatA) > abs(floatB)
    localMax = floatA;
    localMin = floatB;
  else
    localMax = floatB;
    localMin = floatA;
  end
  
  if nargin == 2
    maxDifference = abs(0.001 * localMax);
  else
    maxDifference = tolerance;
  end
  
  isEqual = maxDifference > abs(localMax - localMin);
end