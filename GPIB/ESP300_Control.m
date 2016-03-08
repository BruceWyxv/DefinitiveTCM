classdef ESP300_Control < GPIB_Interface
% Provides commands for interfacing with the EXP300 stage controller
%
% Control of the ESP300 is simplified by abstracting the confusing and
% difficult-to-remember two-character command strings behind
% easy-to-remember function names. Thus, instead of directly sending the
% command "1PA0.0" to move axis 1 to the absolute position of 0.0, the
% function MoveToAbsolute(1, 0.0) is used.
  
  properties (SetAccess = immutable, GetAccess = public)
    activeStages; % Logical array of active stages
  end
  
  properties (Constant = true, GetAccess = public)
    maxStages = 3; % The maximum ID of stages available
  end
  
  methods
    function myself = ESP300_Control(address, name)
    % Construct this class and call the superclass constructor to initialze
    % the interface to the device
      if nargin == 1
        name = GPIB_Interface.GetUnknownDeviceName();
      end
      myself@GPIB_Interface(address, name);
      
      % Turn on the system and check for active stages
      myself.activeStages = [1 1 1]; % Assume all stages are active
      myself.activeStages = ~strcmp(strtrim(myself.Query([1 2 3],'ID')), 'Unknown'); % Block out inactive stages
      
      % Turn on the motors and home the stages
      for i = 1:3
        if myself.activeStages(i)
          myself.TurnOnMotor(i);
          myself.HomeAxis(i);
          myself.WaitForAction(i);
        end
      end
    end
    
    function Beep(myself, varargin)
    % Causes the ESP300 to beep by sending it a command for an invalid
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
    
    function MoveAxis(myself, axis, position, progressBar)
    % Move the specified axis to the desired position. Optionally display a
    % progress bar if requested.
      if isnumeric(axis) && isnumeric(position)
        myself.Command(axis, 'PA', position);
      end
      
      if nargin == 4 && progressBar
        myself.WaitForAction(axis, 'FinalPosition', position, 'Message', 'Please wait while the stage is moving...');
      end
    end
    
    function WaitForAction(myself, axis, varargin)
    % Wait for a stage motion action to complete. Optionally display a
    % progess bar if requested and the appropriate arguments are provided.
      useWaitBar = false;
      
      % Check the input arguments
      if ~isempty(varargin)
        parser = inputParser;
        parser.addRequired('axis', @isnumeric);
        parser.addOptional('finalPosition', 0, @isnumeric);
        parser.addOptional('message', 'Please wait...', @ischar);
        % Parse the input arguments
        parser.KeepUnmatched = true;
        try
          parser.parse(axis, varargin{:});
          % Assign values
          axis = parser.Results.axis;
          message = parser.Results.message;
          finalPosition = parser.Results.finalPosition;
          
          % Peform some calculations
          initialPosition = str2double(myself.Query(axis, 'PA'));
          range = finalPosition - initialPosition;
          useWaitBar = true;
        catch me
          warning('ESP300_Control:InvalidArgument', me.message);
        end
        
        % Open a modal progress bar while we are moving the stage. We don't
        % want the user to be able to change anything until the stage
        % movement is complete. Also, disable the close functionality (a
        % user should not be able to prematurely close the window while the
        % process is still completing.
        progressBar = waitbar(0, message);%, 'WindowStyle', 'modal', 'CloseRequestFcn', '');
        set(progressBar, 'Pointer', 'watch');
      end
  
      % TODO Move the stage and update wait bar with status
      motionCompleted = 0;
      while ~motionCompleted
        % Check the motion done status
        motionCompleted = str2double(myself.Query(axis, 'MD'));
        
        % Update the wait bar if it is used
        if useWaitBar
          currentPosition = str2double(myself.Query(axis, 'PA'));
          percent = (currentPosition - initialPosition) / range;
          waitbar(percent, progressBar);
        end
        
        % Delay before next check, 30 ms is below the typical range of
        % human detection
        pause(.030)
      end

      if useWaitBar
        % Delete the handle to the progress bar. We cannot call the close function
        % since we overode that functionality to disable the user's ability to
        % close the window.
        delete(progressBar);
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
            warning('ESP300_Control:InvalidValueLength', 'An incorrect number of values were provided. Length must be "1" or "%i".\nDefaulting to the first provided argument.', length(axis));
          end
        end
      end
      
      % Validate the command
      if ~ischar(command)
        warning('ESP300_Control:InvalidCommand', 'Invalid command of type "%s"\nA string is required. Command ignored.\n', class(command));
        return;
      end
      
      % Iterate over all the provided axes
      for a = 1:length(axis)
        % Validate the provided axis argument
        if ~myself.IsValidAxis(axis(a))
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
            warning('ESP300_Control:InvalidValue', 'Invalid value of type "%s"\nA number is required. Command ignored.\n', class(value(v)));
            continue;
          end
          
          % Create and send the command
          GPIB_Interface.Communicate(myself, sprintf('%i%s%f', axis(a), command, value(v)));
        end
      end
    end
    
    function HomeAxis(myself, axis)
    % Moves a stage tot he home position
      if isnumeric(axis)
        myself.Command(axis, 'OR');
      end
    end
    
    function reply = Query(myself, axis, command)
    % Construct a command and send to the device
      % Validate the command
      if ~ischar(command)
        warning('ESP300_Control:InvalidCommand', 'Invalid command of type "%s"\nA string is required. Command ignored.\n', class(command));
        return;
      end
      
      % Iterate over all the provided axes
      reply{length(axis)} = [];
      for a = 1:length(axis)
        if ~myself.IsValidAxis(axis(a))
          continue;
        end
        reply{a} = GPIB_Interface.Communicate(myself, sprintf('%i%s?', axis(a), command));
      end
    end
    
    function TurnOffMotor(myself, axis)
    % Turn the motor for an axis off
      if isnumeric(axis)
        myself.Command(axis, 'MF');
      end
    end
    
    function TurnOnMotor(myself, axis)
    % Turn the motor for and axis on
      if isnumeric(axis)
        myself.Command(axis, 'MO');
      end
    end
  end
  
  % Define methods with access by this class only
  methods (Access = private)
    function valid = IsValidAxis(myself, axis)
    % Checks the value of 'axis' and determines if it is a valid axis
    % argument
      if ~isnumeric(axis)
        warning('ESP300_Control:InvalidAxis', 'Invalid axis of type "%s"\nAn integer is required. Command ignored.\n', class(axis));
        valid = false;
      elseif axis < 1 || axis > myself.maxStages
        warning('ESP300_Control:InvalidAxis', 'Invalid axis identifier "%i"\nMust be between 1 and %i. Command ignored.\n', axis, myself.maxStages);
        valid = false;
      elseif ~myself.activeStages(axis)
        warning('ESP300_Control:InactiveAxis', 'Axis "%i" is not currently active.\n', axis);
        valid = false;
      else
        valid = true;
      end
    end
    
    function delete(myself)
    % Turns off the stage motors
      for i = 1:3
        if myself.activeStages(i)
          myself.TurnOffMotor(i);
        end
      end
    end
  end
end
