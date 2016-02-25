% File:         Properties.m
% Author:       Brycen Wendt (brycen.wendt@inl.gov; wendbryc@isu.edu)
% Date Created: 10/22/2015
%
% Usage:        handle        = Properties()
%               specificHeat  = <handle>.GetSpecificHeat(<material>)
%                             = <handle>.GetSpecificHeat(<thermalProps>)
% Inputs:       <handle>        Object handle to the utilities object
%               <material>      String name of material as it appears in the
%                               database
%               <thermalProps>  Structure of material, k, d, and rho
% Outputs:      handle          Object handle to this object
%               specificHeat    Specific heat of the requested material
%
% Description:  A collection of tools related to calculating or operating
%               on properties of materials.

function handle = Properties()
% Assign the function handles
  handle.GetSpecificHeat = @GetSpecificHeat;
end


function specificHeat = GetSpecificHeat(material)
% Return the specific heat of the requested material
%
% If the input argument is a structure then the function will attempt to
% extract the k, D, and rho values to calculate the specific heat. If the
% input argument is a name then the function will attempt to extract the
% values from the thermal properties database and then calculate the
% specific heat.
  database = Database();

  % Deterine the type of the input argument
  if isstruct(material)
    try
      k = material.k;
      d = material.d;
      rho = material.rho;
    catch me
      error('Structure does not have the proper elements. Ensure it contains k, d, and rho.');
    end
    if ~isnumeric(k) || ~isnumeric(d) || ~isnumeric(rho)
      disp('Provided material parameters:');
      disp(material);
      error('All material parameters ''k'', ''d'', and ''rho'' must be numeric');
    end
  elseif ischar(material)
    properties = database.GetThermalProperties(material);
    k = properties.k;
    d = properties.d;
    rho = properties.rho;
  else
    error('Incorrect input type: %s\nInput must be: \n\t1) a structure with elements k, d, and rho, or \n\t2) a string\n', class(material));
  end

  specificHeat = k / (d * rho);
end
