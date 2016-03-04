classdef ESP300_Control < GPIB_Interface
% Provides commands for interfacing with the EXP3000 stage controller
%
% Control of the ESP3000 is simplified by abstracting the confusing and
% difficult-to-remember two-character command strings behind
% easy-to-remember function names. Thus, instead of directly sending the
% command "1PA0.0" to move axis 1 to the absolute position of 0.0, the
% function MoveToAbsolute(1, 0.0) is used.
  
  methods
    function myself = ESP300_Control(address, name)
    % Construct this class and call the superclass constructor to initialze
    % the interface to the device
      if nargin == 1
        name = GPIB_Interface.GetUnknownDeviceName();
      end
      myself@GPIB_Interface(address, name);
    end
    
    function Beep(myself, varargin)
    % Causes the ESP3000 to beep by sending it a command for an invalid
    % axis
      % Check to see if beeping is enabled by the system
      isBeepingEnabled = beep;
      if ~strcmp(isBeepingEnabled, 'on')
        return;
      end
      
      % Beep out the specified pattern
      for i = 1:length(varargin)
        pause(varargin{i}(1));
        myself.PreserveOldCommandAndReply(true);
        myself.RawCommand('99PA0.0');
      end
    end
    
    function MoveAxis(myself, axis, position)
      if isnumeric(axis) && isnumeric(position)
        myself.Command(axis, 'PA', position);
      end
    end
    
    function TurnOffAxis(myself, axis)
      if isnumeric(axis)
        myself.Command(axis, 'MF');
      end
    end
    
    function TurnOnAxis(myself, axis)
      if isnumeric(axis)
        myself.Command(axis, 'MO');
      end
    end
  end
  
  methods (Access = protected)
    function Command(myself, axis, command, value)
    % Construct a command and send to the device
      % Check for an empty value argument
      if nargin < 4
        validValue = false;
        value = '';
      else
        validValue = true;
      
        % Check if there is an equivalent value for each axis
        if length(value) == length(axis)
          matchingValues = true;
        else
          matchingValues = false;
          if ~validValue && length(value) ~= 1
            warning('GPIB_Interface:InvalidValueLength', 'An incorrect number of values were provided. Length must be "1" or "%i".\nDefaulting to the first provided argument.', length(axis));
          end
        end
      end
      
      % Validate the command
      if ~ischar(command)
        warning('GPIB_Interface:InvalidCommand', 'Invalid command of type "%s"\nA string is required. Command ignored.\n', class(command));
        return;
      end
      
      % Iterate over all the provided axes
      for a = 1:length(axis)
        % Validate the provided axis argument
        if ~isnumeric(axis(a))
          warning('GPIB_Interface:InvalidAxis', 'Invalid axis of type "%s"\nAn integer is required. Command ignored.\n', class(axis(a)));
          continue;
        elseif axis(a) < 1 || axis(a) > 3
          warning('GPIB_Interface:InvalidAxis', 'Invalid axis identifier "%i"\nMust be between 1 and 3. Command ignored.\n', axis(a));
          continue;
        end
        
        if ~validValue
          % A value was not provided, send a simple command
          GPIB_Interface.Communicate(myself, sprintf('%i%s', axis(a), command));
        else
          % A value was provided
          if matchingValues
            v = a;
          else
            v = 1;
          end
          
          % Validate the value
          if ~isnumeric(value(v))
            warning('GPIB_Interface:InvalidValue', 'Invalid value of type "%s"\nA number is required. Command ignored.\n', class(value(v)));
            continue;
          end
          
          % Create and send the command
          GPIB_Interface.Communicate(myself, sprintf('%i%s%f', axis(a), command, value(v)));
        end
      end
    end
    
    function reply = Query(myself, axis, command)
    % Construct a command and send to the device
      % Validate the command
      if ~ischar(command)
        warning('GPIB_Interface:InvalidCommand', 'Invalid command of type "%s"\nA string is required. Command ignored.\n', class(command));
        return;
      end
      
      % Iterate over all the provided axes
      reply = zeros(length(axis));
      for a = 1:length(axis)
        if ~isnumeric(axis(a))
          warning('GPIB_Interface:InvalidAxis', 'Invalid axis of type "%s"\nAn integer is required. Command ignored.\n', class(axis(a)));
          continue;
        elseif axis(a) < 1 || axis(a) > 3
          warning('GPIB_Interface:InvalidAxis', 'Invalid axis identifier "%i"\nMust be between 1 and 3. Command ignored.\n', axis(a));
          continue;
        end
        reply(a) = GPIB_Interface.Communicate(myself, sprintf('%i%s?', axis(a), command));
      end
    end
  end
end

