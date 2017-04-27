classdef RS232_Interface < handle
% Provides a framework for essential communications with serial devices.
%
% RS232_Interface is an abstract class that contains the basic raw methods
% and properties for connecting to and controlling a serial instrument. It
% is defined as a handle subclass to prevent an instance of the class
% from being duplicated. Instead, a handle to the class can be duplicated
% and passed around as often as needed.

  % Define properties that can only be set in the class constructor, and
  % read only by this class
  properties (SetAccess = immutable, GetAccess = private)
    deviceHandle; % Handle to the device
  end
  
  % Define properties that are constant but with public read access
  properties (Constant = true, GetAccess = public)
    baudRate = 9600; % Communication speed of the device
    % A former INL employee who knew a lot more than I about communications
    % with RS-232 devices used this parameter. It seems a little long to
    % me, but since we are trying to be generic and support all devices
    % will go with this
    commandDelay = 0.2; % Minimum time to wait between commands
    dataWidth = 8; % Size of a single charater
    terminator = 'CR/LF'; % Terminator signaling and end-of-command
    timeout = 5; % Acceptable delay before an operation fails
  end
  
  % Define properties that can only be set in the class constructor, but
  % with public read access
  properties (SetAccess = immutable, GetAccess = public)
    good; % Contains the current status of the interface
    name; % User-defined name for this device
    port; % Communication port of this device
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
    function myself = RS232_Interface(port, name)
    % Construct this class and initialze the interface to the device
      
      % Create and open the device handle
      retry = true;
      while retry
        [retry, deviceHandle] = RS232_Interface.ConnectDevice(port, myself.baudRate, myself.dataWidth, name, myself.terminator, myself.timeout);
      end
      myself.deviceHandle = deviceHandle;
      myself.good = deviceHandle ~= -1;
      
      % Set the remaining properties
      myself.command = '';
      myself.name = name;
      myself.port = port;
      myself.reply = '';
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
      
      myself.temporary = temporary;
    end
  end
  
  % Define static methods with access by this class and subclasses
  methods (Static = true, Access = protected)
    function reply = Communicate(myself, command, readBytes)
    % Sends a command to the device, optionally requesting a reply
      % Check for valid input
      if ~ischar(command)
        % Only print a warning message, do not send or receive any data
        warning('RS232_Interface:InvalidCommand', 'Invalid command of type "%s"\nA string is required. Command ignored.\n', class(command));
      else
        % Send the command and record the response
        if myself.good
          fwrite(myself.deviceHandle, command);
          
          % Wait just briefly to allow the device to process the previous
          % command.
          pause(myself.commandDelay);
          
          % Get a reply value if one was requested
          if nargout == 1
            if nargin > 2
              reply = fread(myself.deviceHandle, readBytes);
            else
              reply = fread(myself.deviceHandle);
            end
          else
            reply = '';
          end
        else
          warning('RS232_Interface:BadInterface', 'Device interface for "%s% is invalid. Ignoring command "%s".', myself.name, command);
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
    
    function name = GetUnknownDeviceName()
    % Generate a unique name for a device
      persistent id;
      
      if isempty(id)
        id = 1;
      else
        id = id + 1;
      end
      
      name = sprintf('RS232Device%02i', id);
    end
  end
  
  % Define static methods with access by this class only
  methods (Static = true, Access = private)
    function [retry, deviceHandle] = ConnectDevice(port, baudRate, dataWidth, name, terminator, timeout)
    % Attempts to set up a connection to a device
      retry = false;
      try
        deviceHandle = serial(port, ...
                              'BaudRate', baudRate, ...
                              'DataBits', dataWidth, ...
                              'Terminator', terminator, ...
                              'Timeout', timeout);
        fopen(deviceHandle);
      catch initializationError
        message = sprintf('Failed to initialize RS-232 device "%s" at port "%s".\n\nWhat would you like to do?', name, port);
        choice = questdlg(message, 'Connection Error', 'Ignore', 'Abort', 'Retry', 'Retry');
        switch choice
          case 'Abort'
            rethrow(initializationError);
            
          case 'Ignore'
            deviceHandle = -1;

          case 'Retry'
            retry = true;
        end
      end
    end
  end
  
  % Define globally accessible methods
  methods
    function RawCommand(myself, command)
    % Send a command to the device
      RS232_Interface.Communicate(myself, command);
    end
    
    function reply = RawQuery(myself, command)
    % Send a query to the device and record the reply
      reply = RS232_Interface.Communicate(myself, command);
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

