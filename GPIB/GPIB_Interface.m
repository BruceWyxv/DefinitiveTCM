classdef GPIB_Interface < handle
% Provides a framework for essential communications with GPIB devices.
%
% GPIB_Interface is an abstract class that contains the basic raw methods
% and properties for connecting to an controlling a GPIB instrument. It
% is defined as a handle subclass to prevent and instance of the class
% from being duplicated. Instead, a handle to the class can be duplicated
% and passed around as often as needed.

  % Define properties that can only be set in the class constructor, and
  % read only by this class
  properties (SetAccess = immutable, GetAccess = private)
    deviceHandle; % Handle to the device
  end
  
  % Define properties that can only be set in the class constructor, but
  % with public read access
  properties (SetAccess = immutable, GetAccess = public)
    address; % GPIB address of this device
    good; % Contains the current status of the interface
    name; % User-defined name for this device
  end
  
  properties (SetAccess = private, GetAccess = private)
    temporary; % Set the next command to not overwrite the values of the 'command' or 'reply' properties
  end
  
  % Define properties that can only be set by this class, but with public
  % read access
  properties (SetAccess = private, GetAccess = public)
    reply; % The most recent reply received from the device
    command; % The most recent command send to the device
  end
  
  % Define methods that can only be accessed by this class and subclasses
  methods (Access = protected)
    function myself = GPIB_Interface(address, name)
    % Construct this class and initialze the interface to the device
      
      % Create and open the device handle
      % Assume that we are usin a National Instruments board with an index
      % of '0'
      retry = true;
      while retry
        [retry, deviceHandle] = ConnectDevice(address, name);
      end
      myself.deviceHandle = deviceHandle;
      myself.good = strcmp('open', get(deviceHandle, 'Status'));
      
      % Set the remaining properties
      myself.address = address;
      myself.command = '';
      myself.name = name;
      myself.reply = '';
    end
  end
  
  % Define static methods with access by this class and subclasses
  methods (Static = true, Access = protected)
    function name = GetUnknownDeviceName()
    % Generate a unique name for a device
      persistent id;
      
      if isempty(id)
        id = 1;
      else
        id = id + 1;
      end
      
      name = sptrinf('Device%02i', id);
    end
    
    function temporary = PreserveOldCommandAndReply(myself, state)
    % Toggles the next invocation of SendCommand()'s behavior to overwrite
    % the old values of the 'command' and 'reply' properties
      if nargin == 2
        % Change the state to the user-specified state
        temporary = state;
      elseif nargout == 0
        % This is not a query, toggle the state
        temporary = ~myself.temporary;
      else
        % Get the state for the query
        temporary = myself.termporary;
      end
      
      myself.temporary = termporary;
    end
  end
  
  % Define static methods with access by this class only
  methods (Static = true, Access = private)
    function [retry, deviceHandle] = ConnectDevice(address, name)
    % Attempts to set up a connection to a device
      retry = false;
      try
        deviceHandle = gpib('ni', 0, address);
        fopen(deviceHandle);
      catch initializationError
        message = sptrinf('Failed to initialize "%s" with index "%i".\n\nWhat would you like to do?', name, address);
        choice = questdlg(message, 'Ignore', 'Abort', 'Retry', 'Retry');
        switch choice
          case 'Abort'
            rethrow(initializationError);
            
          % No action to take if "Ignore" is selected
          %case 'Ignore'

          case 'Retry'
            retry = true;
        end
      end
    end
  end
  
  % Define globally accessible methods
  methods
    function reply = SendCommand(myself, command)
    % Send a command to the device and record the input
      % Check for valid input
      if ~ischar(command)
        % Only print a warning message, do not send or receive any data
        warning('GPIB_Interface:InvalidCommand', 'Invalid command of type "%s"\nA string is required. Command ignored.\n', class(command));
      else
        % Send the command and record the response
        if myself.good
          fprintf(myself.deviceHandle, command);
          reply = fscanf(myself.deviceHandle);
        else
          warning('GPIB_Interface:BadInterface', 'Device interface is invalid. Ignoring command "%s".', command);
        end

        % Store the command and reply
        if ~myself.temporary
          myself.command = command;
          myself.reply = reply;
        else
          myself.temporary = false;
        end
      end
    end
  end
  
  % Define methods with access by this class only
  methods (Access = private)
    function delete(myself)
    % Closes the interface to the device
      if myself.good
        fclose(myself.deviceHandle);
      end
    end
  end
  
end

