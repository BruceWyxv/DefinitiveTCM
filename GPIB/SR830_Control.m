classdef SR830_Control < GPIB_Interface
% Provides commands for interfacing with the SR830 lock-in amplifier
%
%   Control of the SR830 is simplified via implementation of the required
%   commands as class member functions.
  
  properties (SetAccess = immutable, GetAccess = private)
    indexOfTimeConstantValue; % Handle to the database index lookup function, used to get the index of a time constant
    initialTimeConstantIndex; % Set time constant upon initialization
    valueOfTimeConstantIndex; % Handle to the database time constant function, used to get a time constant value from an index
  end
  
  properties (SetAccess = immutable, GetAccess = public)
    amplitudeChannel; % Output channel of the amplitude data
    phaseChannel; % Output channel of the phase data
  end
  
  methods
    function myself = SR830_Control(address, amplitudeChannel, phaseChannel, name)
    % Construct this class and call the superclass constructor to intialize
    % the interface to the device
      if nargin == 3
        name = GPIB_Interface.GetUnknownDeviceName();
      end
      myself@GPIB_Interface(address, name);
      
      database = Database();
      myself.valueOfTimeConstantIndex = @database.GetLockInAmpTimeConstant;
      myself.indexOfTimeConstantValue = @database.GetIndexOfLockInAmpTimeConstant;
      myself.initialTimeConstantIndex = myself.GetTimeConstantIndex();
      myself.amplitudeChannel = amplitudeChannel;
      myself.phaseChannel = phaseChannel;
    end
    
    function amplitude = GetAmplitude(myself)
    % Get the amplitude of the matching signal
      amplitude = str2double(myself.GetChannelValue(myself.amplitudeChannel));
    end
    
    function value = GetChannelValue(myself, channel)
    % Get the output value of a channel
      value = str2double(GPIB_Interface.Communicate(myself, sprintf('OUTP?%i', channel)));
    end
    
    function phase = GetPhase(myself)
    % Get the phase of the matching signal
      phase = str2double(myself.GetChannelValue(myself.phaseChannel));
    end
    
    function index = GetTimeConstantIndex(myself)
    % Get the indexs of the current time constant
      index = str2double(GPIB_Interface.Communicate(myself, 'OFLT?'));
    end
    
    function value = GetTimeConstantValue(myself)
    % Get the numerical value, in s, of the current time constant
      value = myself.timeConstantValue(myself.GeTimeConstantIndex());
    end
    
    function SetTimeConstantIndex(myself, index)
    % Set the time constant using the index value
      try
        myself.valueOfTimeConstantIndex(index);
      catch
        warning('SR830_Control:BadTimeConstantIndex', 'Ignoring value');
        return;
      end
      GPIB_Interface.Communicate(myself, sprintf('OFLT %i', index));
    end
    
    function SetTimeConstantValue(myself, value)
    % Set the time constant using a numerical value in s. NOTE: the time
    % constant must be one of the options available via the front panel of
    % the lock-in amp
      try
        index = myself.indexOfTimeConstantValue(value);
      catch
        warning('SR830_Control:BadTimeConstantValue', 'Ignoring value');
        return;
      end
      GPIB_Interface.Communicate(myself, sprintf('OFLT %i', index));
    end
  end
  
  methods (Access = private)
    function delete(myself)
    % Prepare the class for deletion by resetting the device to its initial
    % state
      myself.SetTimeConstantIndex(myself.initialTimeConstantIndex);
    end
  end
end

