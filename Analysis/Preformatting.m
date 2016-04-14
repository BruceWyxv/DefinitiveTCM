function [positions, positionOffsets, phases, phaseOffsets, amplitudes, weights] = Preformatting(data, preferences)
% Preformats all the data so that the curves are centered about x=0 and
% offset so that the peak is at y=0
  numberOfPositions = length(data.positions);
  numberOfFrequencies = length(data.frequencies);

  % Scale the data so that the positions reflect the actual distances
  actualPositions = data.positions * preferences.Analysis.scanScaling;
  
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
  if preferences.Analysis.weightFrequencies == 1
    weights(f) = 1.0 / min(phases(f,:));
  else
    weights = ones(1, numberOfFrequencies) ./ min(min(phases));
  end
  weights = abs(weights);
end

