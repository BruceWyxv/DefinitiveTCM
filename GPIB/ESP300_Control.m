classdef ESP300_Control < GPIB_Interface
% Provides commands for interfacing with the ESP300 stage controller
%
% Control of the ESP300 is simplified by implementing the confusing and
% difficult-to-remember two-character command strings as
% easy-to-remember member functions. Thus, instead of directly sending the
% command "1PA0.0" to move axis 1 to the absolute position of 0.0, the
% function MoveToAbsolute(1, 0.0) is used.
  
  properties (SetAccess = immutable, GetAccess = public)
    activeStages; % Logical array of active stages
    originalStageSpeeds; % Speed of the stages upon loading the class
  end
  
  properties (Constant = true, GetAccess = public)
    maxStages = 3; % The maximum ID of stages available
  end
  
  properties (SetAccess = private, GetAccess = public)
    slowStageSpeeds; % Fast stage speeds
    fastStageSpeeds; % Slow stage speeds
  end
  
  methods
    function myself = ESP300_Control(address, name)
    % Construct this class and call the superclass constructor to initialze
    % the interface to the device
      if nargin < 2
        name = GPIB_Interface.GetUnknownDeviceName();
      end
      myself@GPIB_Interface(address, name);
      
      % Turn on the system and check for active stages
      myself.activeStages = ones(1, myself.maxStages); % Assume all stages are active
      myself.activeStages = ~strcmp(strtrim(myself.Query(1:myself.maxStages, 'ID')), 'Unknown'); % Block out inactive stages
      myself.TurnOnMotor(1:myself.maxStages);
      
      % Get the stage speeds
      myself.originalStageSpeeds = myself.GetStageSpeed(1:myself.maxStages);
      myself.fastStageSpeeds = myself.originalStageSpeeds * 0.6;
      myself.slowStageSpeeds = myself.originalStageSpeeds * 0.1;
      myself.UseSlowSpeed();
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
    
    function coordinates = GetAbsoluteCoordinates(myself, axis)
    % Get the absolute coordinates of the requested axis
      coordinates = str2double(myself.Query(axis, 'PA'));
    end
    
    function speed = GetStageSpeed(myself, axis)
    % Get the current speed of the requested axis
      speed = str2double(myself.Query(axis, 'VA'));
    end
    
    function positionHistory = HomeAxis(myself, axis)
    % Moves a stage to the home position
      if isnumeric(axis)
        myself.Command(axis, 'OR');
      end
      
      % Read the instantaneous positions
      maxIterations = 4000; % Enough for 2 minutes of homing action
      positionHistory = zeros(1, maxIterations);
      for i = 1:maxIterations
        pause(.030);
        positionHistory(i) = str2double(myself.Query(axis, 'TP'));
        
        % Break if the motion is completed
        if str2double(myself.Query(axis, 'MD')) == 1
          break;
        end
      end
      
      positionHistory = positionHistory(positionHistory ~= 0);
    end
    
    function valid = IsValidAxes(myself, axes)
    % Checks the value(s) of 'axes' and determines if it is valid
      valid = true;
      for a = 1:length(axes)
        axis = axes(a);
        if ~isnumeric(axis)
          warning('ESP300_Control:InvalidAxis', 'Invalid axis of type "%s"\nAn integer is required. Command ignored.\n', class(axis));
          valid = false;
        elseif axis < 1 || axis > myself.maxStages
          warning('ESP300_Control:InvalidAxis', 'Invalid axis identifier "%i"\nMust be between 1 and %i. Command ignored.\n', axis, myself.maxStages);
          valid = false;
        elseif ~myself.activeStages(axis)
          valid = false;
        else
          valid = valid & true;
        end
      end
    end
    
    function MinimizeHysteresis(myself, axes, firstTwoPositions)
    % Minimize stage hysteresis by approaching the initial position from
    % the opposite direction
      if ~isnumeric(firstTwoPositions) || length(firstTwoPositions) < 1
        warning('ESP300_Control:InsufficientInformation', 'Must provide the first two positions in order to provide directionality for hysteresis minimization.');
        return;
      end
      
      % Only minimize hysteresis if the axis is actually moving
      for a = 1:length(axes)
        if ~isFloatEqual(firstTwoPositions(a,1), firstTwoPositions(a,2))
          hysteresisPosition = firstTwoPositions(a,1) + 4 * (firstTwoPositions(a,1) - firstTwoPositions(a,2));
          myself.MoveAxis(axes(a), hysteresisPosition);
          myself.WaitForAction(axes(a));
        end
      end
    end
    
    function MoveAxis(myself, axes, position, progressBar)
    % Move the specified axis to the desired position. Optionally display a
    % progress bar if requested.
      if isnumeric(axes) && isnumeric(position)
        myself.Command(axes, 'PA', position);
      else
        warning('ESP300_Control:BadArgument', 'Both ''axis'' and ''position'' must be numeric.');
        return;
      end
      
      if nargin == 4 && progressBar
        myself.WaitForAction(axes, 'Message', 'Please wait while the stage is moving...');
      end
    end
    
    function SetLimits(myself, axes, limits)
    % Set the travel limits for the stages
      for i = 1:length(axes)
        myself.SetStageLimits(axes(i), limits(i,:));
      end
    end
    
    function SetSlowSpeed(myself, axes, speed)
    % Set the current speed of the requested axis
      if ~myself.IsValidAxes(axes)
        return;
      end
      
      if length(speed) ~= length(axes)
        if isempty(speed)
          warning('ESP300_Control:NoSpeed', 'No speed value provided, not setting slow speed value.');
          return;
        end
        if length(speed) ~= 1
          warning('ESP300_Control:AxesMismatch', 'Not enough values in the array ''speed'', must be either ''1'' or equal to the number of ''axes'' specified.');
        end
        speed = ones(1, length(axes)) * speed(1);
      end
        
      for a = 1:length(axes)
        myself.slowStageSpeeds(a) = speed(a);
      end
    end
    
    function SetToZero(myself, axes)
    % Set the current position of the axis as 0.0
     if isnumeric(axes)
       myself.Command(axes, 'DH');
     else
       warning('ESP300_Control:BadArgument', '''axis'' must be numeric.');
     end
    end
    
    function UseFastSpeed(myself, axes)
    % Set the axes to use the 'fast' speed
      if nargin == 1
        axes = 1:myself.maxStages;
      end
      myself.SetAxesSpeed(axes, myself.fastStageSpeeds(axes));
    end
    
    function UseSlowSpeed(myself, axes)
    % Set the axes to use the 'slow' speed
      if nargin == 1
        axes = 1:myself.maxStages;
      end
      myself.SetAxesSpeed(axes, myself.slowStageSpeeds(axes));
    end
    
    function WaitForAction(myself, axes, varargin)
    % Wait for a stage motion action to complete. Optionally display a
    % progess bar if requested and the appropriate arguments are provided.
      if ~myself.IsValidAxes(axes)
        return;
      end
      
      useWaitBar = false;
      
      % Check the input arguments
      if ~isempty(varargin)
        parser = inputParser;
        parser.addRequired('axes', @isnumeric);
        parser.addOptional('message', 'Please wait for stage action to complete...');
        % Parse the input arguments
        parser.KeepUnmatched = true;
        try
          parser.parse(axes, varargin{:});
          % Assign values
          axes = parser.Results.axes;
          message = parser.Results.message;
          
          % Peform some calculations
          initialPosition = str2double(myself.Query(axes, 'TP'));
          finalPosition = str2double(myself.Query(axes, 'PA'));
          range = abs(finalPosition - initialPosition);
          useWaitBar = true;
        catch me
          warning('ESP300_Control:InvalidArgument', me.message);
        end
        
        % Open a modal progress bar while we are moving the stage. We don't
        % want the user to be able to change anything until the stage
        % movement is complete. Also, disable the close functionality (a
        % user should not be able to prematurely close the window while the
        % process is still completing.
        progressBar = waitbar(0, message, 'WindowStyle', 'modal', 'CloseRequestFcn', '');
        set(progressBar, 'Pointer', 'watch');
      end
  
      % TODO Move the stage and update wait bar with status
      motionCompleted = 0;
      while ~motionCompleted
        % Check the motion done status
        motionCompleted = all(str2double(myself.Query(axes, 'MD')));
        
        % Update the wait bar if it is used
        if useWaitBar
          currentPosition = str2double(myself.Query(axes, 'TP'));
          percent = sum(abs((currentPosition - initialPosition) ./ range)) / length(axes);
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
        if ~myself.IsValidAxes(axis(a))
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
    
    function reply = Query(myself, axes, command)
    % Construct a command and send to the device
      % Validate the command
      if ~ischar(command)
        warning('ESP300_Control:InvalidCommand', 'Invalid command of type "%s"\nA string is required. Command ignored.\n', class(command));
        return;
      end
      
      % Iterate over all the provided axes
      reply{length(axes)} = [];
      for a = 1:length(axes)
        if ~myself.IsValidAxes(axes(a))
          continue;
        end
        reply{a} = GPIB_Interface.Communicate(myself, sprintf('%i%s?', axes(a), command));
      end
    end
    
    function SetStageLimits(myself, axis, limits)
    % Sets the travel limits of an axis
      if limits(1) > limits(2)
        temp = limits(1);
        limits(1) = limits(2);
        limits(2) = temp;
      end
      
      % If needed, move the stage to within the limits
      % TODO maybe comfirm with the user before moving stage?
      position = str2double(myself.Query(axis, 'PA'));
      if position < limits(1)
        myself.MoveAxis(axis, limits(1));
      elseif position > limits(2)
        myself.MoveAxis(axis, limits(2));
      end
      myself.WaitForAction(axis);
      
      % Set the limits
      % Configure the controller. 5H is hexadecimal code for:
      %   1) enable limit checking (bit 0)
      %   2) abort motion if limit exceeded (bit 2)
      myself.Command(axis, 'ZS 5H');
      myself.Command(axis, 'SL', limits(1));
      myself.Command(axis, 'SR', limits(2));
    end
    
    function SetAxesSpeed(myself, axes, speed)
    % The the speed of the axes to speed
      myself.Command(axes, 'VA', speed);
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
    function delete(myself)
    % Reset the stage speeds
      myself.SetAxesSpeed(1:myself.maxStages, myself.originalStageSpeeds);
      
    % Turns off the stage motors
      for i = 1:myself.maxStages
        if myself.activeStages(i)
          myself.TurnOffMotor(i);
        end
      end
    end
  end
end

