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
    frequency;
    offset;
    power;
    voltage;
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
      myself.TurnOff();
    end
    
    function SetFrequency(myself, frequency)
    % Sets the frequency of the output
      myself.SendCommand(sprintf('FREQ %i', frequency));
      myself.frequency = frequency;
    end
    
    function SetPower(myself, power)
    % Sets the laser power, on a scale from 0 to 100
      if power < 0
        power = 0;
      elseif power > 100
        power = 100;
      end
      
      voltagePP = (myself.maxVoltage - myself.minVoltage) * (power / 100) + myself.minVoltage;
      myself.SetVoltage(voltagePP);
      myself.power = power;
    end
    
    function TurnOff(myself)
    % Turns the power off
      myself.SetPower(0);
      myself.SetFrequency(100);
    end
    
    function TurnOn(myself)
    % Turns the power on and sets the laser to a minimal output level
      myself.SetPower(100);
      myself.SetFrequency(1e3);
    end
  end
  
  methods (Access = protected)
    function SendCommand(myself, command)
    % Sends a command, using the required line feed at the end although
    % tesing indicates that it is not actually needed.)
      GPIB_Interface.Communicate(myself, sprintf('%s\n', command));
    end
    
    function SetVoltage(myself, voltage)
    % Sets the maximum voltage of the output
      if voltage > myself.maxVoltage
        warning('DG345_Control:MaxVoltageExceeded', 'Setting voltage to maximum allowable voltage of %f V', myself.maxVoltage);
        voltage = myself.maxVoltage;
      elseif voltage < myself.minVoltage * 2
        if voltage < 0
          % Only issue a warning for negative values. We use '0' to 'turn
          % off' the laser
          warning('DG345_Control:MinVoltageExceeded', 'Setting voltage to minimal allowable voltage');
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

