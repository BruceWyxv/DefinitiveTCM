classdef SR830_Control < GPIB_Interface
% Provides commands for interfacing with the SR830 lock-in amplifier
%
%   Control of the SR830 is simplified via implementation of the required
%   commands as class member functions.

  properties (Constant = true, GetAccess = public)
    amplitudeOutputIndex = 3; % Data output tha corresponds to the signal amplitude
    maxAuxOutputVoltage = 10.5; % Maximum voltage that can be sent via the auxilliary outputs
    minAuxOutputVoltage = -10.5; % Minimum voltage that can be sent via the auxilliary outputs
    phaseOutputIndex = 4; % Data output that corresponds to the phase difference
  end
  
  properties (SetAccess = immutable, GetAccess = protected)
    indexOfSensitivityConstantValue; % Handle to the database index lookup function, used to get the index of a sensitivity constant
    indexOfTimeConstantValue; % Handle to the database index lookup function, used to get the index of a time constant
    initialSensitivityConstantIndex; % Original sensitivity constant upon connection
    initialTimeConstantIndex; % Original time constant upon connection
    valueOfSensitivityConstantIndex; % Handle to the database time constant function, used to get a sensitivity constant value from an index
    valueOfTimeConstantIndex; % Handle to the database time constant function, used to get a time constant value from an index
  end
  
  properties (SetAccess = private, GetAccess = public)
    chillTime; % The amount of time required to stabilize a reading, equal in duration to 6 time constants
  end
  
  methods
    function myself = SR830_Control(address, name)
    % Construct this class and call the superclass constructor to intialize
    % the interface to the device
      if nargin == 1
        name = GPIB_Interface.GetUnknownDeviceName();
      end
      myself@GPIB_Interface(address, name);
      
      database = Database();
      myself.indexOfSensitivityConstantValue = @database.GetIndexOfLockInAmpSensitivityConstant;
      myself.indexOfTimeConstantValue = @database.GetIndexOfLockInAmpTimeConstant;
      myself.initialSensitivityConstantIndex = myself.GetSensitivityConstantIndex();
      myself.initialTimeConstantIndex = myself.GetTimeConstantIndex();
      myself.valueOfSensitivityConstantIndex = @database.GetLockInAmpSensitivityConstant;
      myself.valueOfTimeConstantIndex = @database.GetLockInAmpTimeConstant;
    end
    
    function Chill(myself)
    % Wait 7 time constants so that the readings stabilize
     pause(myself.chillTime);
    end
    
    function amplitude = GetAmplitude(myself)
    % Get the amplitude of the matching signal
      amplitude = 0;
      samples = 5;
      for i = 1:samples
        amplitude = amplitude + myself.GetAmplitudeSingle();
      end
      amplitude = amplitude / samples;
    end
    
    function amplitude = GetAmplitudeSingle(myself)
    % Get the amplitude of the matching signal
      amplitude = myself.GetSignalValue(myself.amplitudeOutputIndex);
    end
    
    function value = GetAuxInputValue(myself, index)
    % Gets the current reading on the selected auxillary input
      value = str2double(GPIB_Interface.Communicate(myself, sprintf('OAUX?%i', index)));
      
      % Check for a NaN, recursively call if a NaN is returned
      % NaNs are returned only when a communication timeout occurs
      if isnan(value)
        value = myself.GetAuxInputValue(index);
      end
    end
    
    function phase = GetPhase(myself)
    % Get the phase of the matching signal
      phase = myself.GetSignalValue(myself.phaseOutputIndex);
    end
    
    function shift = GetPhaseShift(myself)
    % Gets the current phase shift
      shift = str2double(GPIB_Interface.Communicate(myself, 'PHAS?'));
    end
    
    function index = GetSensitivityConstantIndex(myself)
    % Get the index of the current sensitivity constant
      index = str2double(GPIB_Interface.Communicate(myself, 'SENS?'));
    end
    
    function value = GetSensitivityConstantValue(myself)
    % Get the numerical value, in mV/nA, of the current sensitivity
    % constant
      value = myself.sensitivityConstantValue(myself.GetSensitivityConstantIndex());
    end
    
    function value = GetSignalValue(myself, index)
    % Get the output component of the signal
      value = str2double(GPIB_Interface.Communicate(myself, sprintf('OUTP?%i', index)));
      
      % Check for a NaN, recursively call if a NaN is returned
      % NaNs are returned only when a communication timeout occurs
      if isnan(value)
        value = myself.GetSignalValue(index);
      end
    end
    
    function index = GetTimeConstantIndex(myself)
    % Get the index of the current time constant
      index = str2double(GPIB_Interface.Communicate(myself, 'OFLT?'));
    end
    
    function value = GetTimeConstantValue(myself)
    % Get the numerical value, in s, of the current time constant
      value = myself.timeConstantValue(myself.GeTimeConstantIndex());
    end
    
    function SetAuxOutputVoltage(myself, index, voltage)
    % Sets the output voltage of one of the auxillary output channels
      if voltage < myself.minAuxOutputVoltage
        voltage = myself.minAuxOutputVoltage;
      elseif voltage > myself.maxAuxOutputVoltage
        voltage = myself.maxAuxOutputVoltage;
      end
      
      GPIB_Interface.Communicate(myself, sprintf('AUXV %i,%f', index, voltage));
    end
    
    function SetPhaseShift(myself, shift)
    % Sets the current phase shift
      GPIB_Interface.Communicate(myself, sprintf('PHAS %f', shift));
    end
    
    function SetSensitivityConstantIndex(myself, index)
    % Set the sensitivity constant using the index value
      try
        myself.valueOfSensitivityConstantIndex(index);
        GPIB_Interface.Communicate(myself, sprintf('SENS %i', index));
      catch
        warning('SR830_Control:BadSensitivityConstantIndex', 'Ignoring value');
      end
    end
    
    function SetSensitivityConstantValue(myself, value)
    % Set the sensitivity constant using a numerical value in mV/nA. NOTE:
    % the sensitivity constant must be one of the options available via the
    % front panel of the lock-in amp
      try
        index = myself.indexOfSensitivityConstantValue(value);
        myself.SetSensitivityConstantIndex(index)
      catch
        warning('SR830_Control:BadSensitivityConstantValue', 'Ignoring value');
      end
    end
    
    function SetTimeConstantIndex(myself, index)
    % Set the time constant using the index value
      try
        value = myself.valueOfTimeConstantIndex(index);
        GPIB_Interface.Communicate(myself, sprintf('OFLT %i', index));
        myself.chillTime = value * 7;
      catch
        warning('SR830_Control:BadTimeConstantIndex', 'Ignoring value');
      end
    end
    
    function SetTimeConstantValue(myself, value)
    % Set the time constant using a numerical value in s. NOTE: the time
    % constant must be one of the options available via the front panel of
    % the lock-in amp
      try
        index = myself.indexOfTimeConstantValue(value);
        myself.SetTimeConstantIndex(index);
      catch
        warning('SR830_Control:BadTimeConstantValue', 'Ignoring value');
      end
    end
  end
  
  methods (Access = private)
    function delete(myself)
    % Prepare the class for deletion by resetting the device to its initial
    % state
      myself.SetSensitivityConstantIndex(myself.initialSensitivityConstantIndex);
      myself.SetTimeConstantIndex(myself.initialTimeConstantIndex);
      GPIB_Interface.Communicate(myself, 'OVRM 0');
    end
  end
end

