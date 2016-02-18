% File:         Utilities.m
% Author:       Brycen Wendt (brycen.wendt@inl.gov; wendbryc@isu.edu)
% Date Created: 10/22/2015
%
% Usage:        handle        = Utilities()
%               fileName      = <handle>.GetFileName(<directory>, <base>, <index>)
%               specificHeat  = <handle>.GetSpecificHeat(<material>)
%                             = <handle>.GetSpecificHeat(<thermalProps>)
%               data          = <handle>.LoadData(<directory>, <base>, <count>)
% Inputs:       <base>          Base of the file name, used to construct the
%                               file name as <base>All<index>.mat
%               <count>         Number of frequency sets to load when loading
%                               data
%               <directory>     Absolute path of the data file directory
%               <handle>        Object handle to the utilities object
%               <index>         Index number of the frequency set being
%                               requested
%               <material>      String name of material as it appears in the
%                               database
%               <thermalProps>  Structure of material, k, d, and rho
% Outputs:      fileName        Absolute path to the TCM data file
%               handle          Object handle to the database object
%               specificHeat    Specific heat of the requested material
%
% Description:  The utilities file is a basic collection of universal tools that
%               can be leveraged anywhere within the Definitive TCM code.

function handle = Utilities()
    % Assign the function handles
    handle.GetFileName = @GetFileName;
    handle.GetSpecificHeat = @GetSpecificHeat;
end

function fileName = GetFileName(directory, fileNameBase, index)
    % Assembles the file name from the components and return the string
    fileName = sprintf('%s/%sAll%i.mat', directory, fileNameBase, index);
end

function specificHeat = GetSpecificHeat(material)
    % Return the specific heat of the requested material
    %
    % If the input argument is a structure then the function will attempt to
    % extract the k, D, and rho values to calculate the specific heat. If the
    % input argument is a name then the function will attempt to extract the
    % values from the thermal properties database and then calculate the
    % specific heat.
    k = 0;
    d = 0;
    rho = 0;
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

function data = LoadData(directory, baseName, numberOfFrequencies)
    % Collects all data from a set of files
    
end
