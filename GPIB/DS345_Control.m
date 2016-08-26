classdef DS345_Control < GPIB_Interface
% Provides commands for interfacing with the SRS DS345 function generator
%
%   Control of the SRS DS345 is provided via implementation of the required
%   commands as class member functions.
  
  properties (Constant = true, GetAccess = public)
    maxVoltage = 5.0; % Maximum output voltage of the DS345
    minVoltage = 0.05; % The attached pump laser will go bad if a negative volage is ever applied
  end
  
  properties (SetAccess = private, GetAccess = public)
    frequency; % The pulse frequency
    isOn; % Boolean state for if the laser is on
    offset; % Signal offset
    powerSetpoint; % Relative power level on a scale of 0 to 100
    voltage; % Signal amplitude
  end
  
  methods
    function myself = DS345_Control(address, name)
    % Construct this class and call the superclass constructor to intialize
    % the interface to the device
      if nargin == 1
        name = GPIB_Interface.GetUnknownDeviceName();
      end
      myself@GPIB_Interface(address, name);
      
      % Use a SINE function
      myself.SendCommand('FUNC 0');
      % Ensure signal inversion is off
      myself.SendCommand('INVT 0');
      
      % Initialize the power to off
      myself.powerSetpoint = 0;
      myself.TurnOff();
    end
    
    function SetFrequency(myself, frequency)
    % Sets the frequency of the output
      myself.SendCommand(sprintf('FREQ %i', frequency));
      myself.frequency = frequency;
    end
    
    function SetPowerSetpoint(myself, powerLevel)
    % Sets the laser power, on a scale from 0 to 100
      powerLevel = real(powerLevel);
      if powerLevel <= 0
        powerLevel = 0;
      elseif powerLevel > 100
        powerLevel = 100;
      end
      
      % Will we need to reset the function generator output?
      reset = false;
      if myself.powerSetpoint ~= powerLevel && myself.isOn
        reset = true;
      end
      
      % Update the setpoing
      myself.powerSetpoint = powerLevel;
      
      % Reset if needed
      if reset
        myself.TurnOff();
        myself.TurnOn();
      end
    end
    
    function TurnOff(myself)
    % Turns the power off
      myself.SetVoltage(myself.GetVoltagePPFromPower(0));
      myself.SetFrequency(100);
      myself.isOn = false;
    end
    
    function TurnOn(myself)
    % Turns the power on and sets the laser to  output level
      myself.SetVoltage(myself.GetVoltagePPFromPower(myself.powerSetpoint));
      myself.SetFrequency(1e3);
      myself.isOn = true;
    end
  end
  
  methods (Access = protected)
    function voltagePP = GetVoltagePPFromPower(myself, powerLevel)
    % Converts the power from a scale of 0 to 100 into a peak-to-peak
    % voltage for the function generator
      voltagePP = (myself.maxVoltage - myself.minVoltage) * (powerLevel / 100) + myself.minVoltage;
    end
    
    function SendCommand(myself, command)
    % Sends a command, using the required line feed at the end although
    % tesing indicates that it is not actually needed.)
      GPIB_Interface.Communicate(myself, sprintf('%s\n', command));
    end
    
    function SetVoltage(myself, voltage)
    % Sets the maximum voltage of the output
      if voltage > myself.maxVoltage
        warning('DS345_Control:MaxVoltageExceeded', 'Setting voltage to maximum allowable voltage of %f V', myself.maxVoltage);
        voltage = myself.maxVoltage;
      elseif voltage < myself.minVoltage * 2
        if voltage < 0
          % Only issue a warning for negative values. We use '0' to 'turn
          % off' the laser
          warning('DS345_Control:MinVoltageExceeded', 'Setting voltage to minimal allowable voltage');
        end
        voltage = myself.minVoltage + .01;
      end
      
      % Calculate some values
      peak2Peak = voltage - myself.minVoltage;
      dcOffset = (peak2Peak + myself.minVoltage) / 2;
      
      % Send the values. We will first emit a pure DC signal, the shift the
      % DC amplitude to the offset, then finally add in the AC component.
      %
      % This process ensures that the laser never sees a negative signal
      myself.SendCommand('AMPL 0.0VP');
      myself.SendCommand(sprintf('OFFS %f', dcOffset));
      myself.SendCommand(sprintf('AMPL %fVP', peak2Peak));
      
      myself.offset = dcOffset;
      myself.voltage = voltage;
    end
  end
  
  methods (Access = private)
    function delete(myself)
    % Turns off the laser
      myself.TurnOff();
    end
  end
end

