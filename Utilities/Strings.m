% File:         Strings.m
% Author:       Brycen Wendt (brycen.wendt@inl.gov; wendbryc@isu.edu)
% Date Created: 02/25/2016
%
% Usage:        handle        = Strings()
%               [u, s]        = <handle>.GetSmallestUniqueIdentifier(<strings>)
% Inputs:       <handle>        Object handle to this object object
%               <strings>       A cell array of strings to be processed
% Outputs:      handle          Object handle to this object
%               u               The length of the smallest unique string
%               s               The length of the shortest string
%
% Description:  A collection of tools related to string operations that
%               can be leveraged anywhere within the DefinitiveTCM code.

function handle = Strings()
% Assign the function handles
  handle.GetSmallestUniqueIdentifier = @GetSmallestUniqueIdentifier;
end


function [uniqueLength, shortestLength] = GetSmallestUniqueIdentifier(cellOfStrings)
% Searches the loaded database and finds the shortest string by which a
% material may be identified.
  uniqueLength = 1;
  lengths = cellfun(@length, cellOfStrings);
  shortestLength = min(lengths);
  maximumLength = max(lengths);
  alphanumeric = ['0':'9', 'a':'z'];
  currentMatches = {''; cellOfStrings};
  
  while uniqueLength <= maximumLength
    previousMatches = currentMatches;
    currentMatches = cell(2, 0);
    for i = 1:length(alphanumeric)
      matches = FindBeginningMatchesAddingCharacter(previousMatches, alphanumeric(i));
      if ~isempty(matches)
        currentMatches = [currentMatches, matches]; %#ok<AGROW>
      end
    end
    if isempty(currentMatches)
      break;
    else
      uniqueLength = uniqueLength + 1;
    end
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Private functions not exposed outside this .m file %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matches = FindBeginningMatchesAddingCharacter(cellOfStrings, character)
% Scans a list of strings and returns a cell array of any matches found
  % Create an empy cell array
  matches = cell(2, 0);
  
  % Iterate over all the elements
  for i = 1:size(cellOfStrings, 2)
    findMe = sprintf('%s%c', cellOfStrings{1,i}, character);
    sameBeginnings = cellOfStrings{2,i}(strncmpi(cellOfStrings{2,i}, findMe, length(findMe)));
    
    % Add a set of matches only if more than one match were found
    if length(sameBeginnings) > 1
      matches = [matches, {findMe; sameBeginnings}]; %#ok<AGROW>
    end
  end
end
