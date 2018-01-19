function [bestIndex, thicknesses, difference, transmissionRatios] = CalculateFilmThickness(transmissionRatio)
% Syntax: [thicknesses, bestIndex, difference, transmissionRatios] = CalculateFilmThickness(transmissionRatio)
%
% Description:  This function uses the measured tranmission ratio of a gold
%               film on a pyrex sample to determine film thickness based
%               on bulk permativity.
%
% Inputs:       transmissionRatio: The ratio of tranmission through the
%                   surrogate sample vs. open transmission at 488 nm
%
% Outputs:      bestIndex: The index of the thickness in @thicknesses that
%                   best matches the provided @transmissionRatio
%               thicknesses: An array of the possible film thicknesses from
%                   0 nm to 250 nm in increments of 1 nm
%               difference: The magnitude of the difference between the
%                   best match in @transmissionRatios and 
%                   @transmissionRatio
%               transmissionRatios: An array of the evaluated transmission
%                   ratios

l = 488e-9;  % Wavelength of light

% Define material optical properties, all values are @ 488nm
n0 = 1;               % Index of refraction of air
%ns = 1.48;            % Index of refraction of substrate (pyrex)
ns = 1.52;            % Index of refraction of substrate (BK7)
%ns = 1.436;            % Index of refraction of substrate (CaF2)
ks = 0;               % Imaginary part of index of refraction of substrate
ng = 1.09;            % Index of refraction of gold
kg = 1.8;             % Imaginary part of index of refraction of gold
h = (0:1:250) * 1e-9;   % Array of possible thickness values
eta = 2 * pi * h / l;

% Define some repeated values
a = (ng - n0)^2 + kg^2;
d = (ng + n0)^2 + kg^2;
b = (ng + ns)^2 + (kg + ks)^2;
c = (ng - ns)^2 + (kg - ks)^2;

% r = (n0^2 + ns^2 + ks^2)...
%     * (ng^2 + kg^2) - n0^2 * (ns^2 + ks^2) - 4 * n0 * kg * (kg * ns - ng * ks);
% s = 2 * kg * (ns - n0) * (ng^2 + kg^2 + n0 * ns)...
%     + 2 * ks * (kg * ks * n0 + 4 * (n0^2 - ng^2 - kg^2));
t = (n0^2 + ns^2 + ks^2)...
    * (ng^2 + kg^2) - n0^2 * (ns^2 + ks^2) + 4 * n0 * kg * (kg * ns - ng * ks);
u = 2 * kg * (ns + n0) * (ng^2 + kg^2 - n0 * ns)...
    - 2 * ks * (kg * ks * n0 - 4 * (n0^2 - ng^2 - kg^2));

% Evaluate the transmission ratios
% R = (a * b * exp(2 * kg * eta)...
%      + c * d * exp(-2 * kg * eta)...
%      + 2 * r * cos(ng * eta)...
%      + 2 * s * sin(ng * eta))...
%     ./ (b * d*exp(2 * kg * eta)...
%         + a * c * exp(-2 * kg * eta)...
%         + 2 * t * cos(ng * eta)...
%         + 2 * u * sin(ng * eta));
transmissionRatios = (16 * n0 * ns * (ng^2 + kg^2))...
                     ./ (b * d * exp(2 * kg * eta)...
                         + a * c * exp(-2 * kg * eta)...
                         + 2 * t * cos(ng * eta)...
                         + 2 * u * sin(ng * eta));

thicknesses = h;
[difference, bestIndex] = min(abs(transmissionRatios - transmissionRatio));

maxIndex = length(h);
if bestIndex == length(h) && difference > abs(transmissionRatios(maxIndex) - transmissionRatios(maxIndex - 1))
  uiwait(warndlg(['The film thickness may actually be greater than '...
                  num2str(max(h) * 1e9) ' nm based on the measured '...
                  'transmission ratio of ' num2str(transmissionRatio)],...
                 'Film Thickness Warning',...
                 'modal'));
end