% File:         Files.m
% Author:       Brycen Wendt (brycen.wendt@inl.gov; wendbryc@isu.edu)
% Date Created: 10/22/2015
%
% Usage:        handle        = Files()
%               fileName      = <handle>.GetFileName(<directory>, <base>, <index>)
%               data          = <handle>.LoadData(<directory>, <base>, <count>)
% Inputs:       <base>          Base of the file name, used to construct the
%                               file name as <base>All<index>.mat
%               <count>         Number of frequency sets to load when loading
%                               data
%               <directory>     Absolute path of the data file directory
%               <handle>        Object handle to this object object
%               <index>         Index number of the frequency set being
%                               requested
% Outputs:      data            Structure containing the data extracted
%                               from a file
%               fileName        Absolute path to the TCM data file
%               handle          Object handle to this object
%
% Description:  A collection of tools related to file access operations
%               that can be leveraged anywhere within the DefinitiveTCM
%               code.

function handle = Files()
% Assign the function handles
  handle.GetFileName = @GetFileName;
  handle.LoadData = @LoadData;
end


function fileName = GetFileName(directory, fileNameBase, index)
% Assembles the file name from the components and return the string
  fileName = sprintf('%s/%sAll%i.mat', directory, fileNameBase, index);
end


function data = LoadData(directory, baseName, numberOfFrequencies)
% Collects all data from a set of files

end
