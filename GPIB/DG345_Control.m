classdef DG345_Control < GPIB_Interface
% Provides commands for interfacing with the SRS DG345 function generator
%
%   Control of the SRS DG345 is provided via implementation of the required
%   commands as class member functions.
  
  properties (Constant = true, GetAccess = public)
    maxVoltage = 5.0; % Maximum output voltage of the DG345
    minVoltage = 0.05; % The attached pump laser will go bad if a negative volage is ever applied
  end
  
  properties (SetAccess = private, GetAccess = public)
    frequency;
    offset;
    power;
    voltage;
  end
  
  methods
    function myself = DG345_Control(address, name)
    % Construct this class and call the superclass constructor to intialize
    % the interface to the device
      if nargin == 1
        name = GPIB_Interface.GetUnknownDeviceName();
      end
      myself@GPIB_Interface(address, name);
      
      % Use a SINE function
      GPIB_Interface.Communicate(myself, 'FUNC 0');
      % Ensure signal inversion is off
      GPIB_Interface.Communicate(myself, 'INVT 0');
      
      % Set the intial conditions
      myself.SetFrequency(1e3);
      myself.SetPower(0);
    end
    
    function SetFrequency(myself, frequency)
    % Sets the frequency of the output
      GPIB_Interface.Communicate(myself, sprintf('FREQ %i', frequency));
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
  end
  
  methods (Access = protected)
    function SetVoltage(myself, voltage)
    % Sets the maximum voltage of the output
      if voltage > myself.maxVoltage
        warning('DG345_Control:MaxVoltageExceeded', 'Setting voltage to maximum allowable voltage of %f V', myself.maxVoltage);
        voltage = myself.maxVoltage;
      elseif voltage < myself.minVoltage
        if voltage ~= 0
          % Only issue a warning for non-zero values. We use '0' to 'turn
          % off' the laser
          warning('DG345_Control:MinVoltageExceeded', 'Setting voltage to minimum allowable voltage of %f V', myself.minVoltage);
        end
        voltage = myself.minVoltage;
      end
      
      % Calculate some values
      peak2Peak = voltage - myself.minVoltage;
      dcOffset = (peak2Peak + myself.minVoltage) / 2;
      
      % Send the values. We will first emit a pure DC signal, the shift the
      % DC amplitude to the offset, then finally add in the AC component.
      %
      % This process ensures that the laser never sees a negative signal
      GPIB_Interface.Communicate(myself, 'AMPL 0.0VP');
      GPIB_Interface.Communicate(myself, sprintf('OFFS %f', dcOffset));
      GPIB_Interface.Communicate(myself, sprintf('AMPL %fVP', peak2Peak))
      
      myself.offset = dcOffset;
      myself.voltage = voltage;
    end
  end
  
  methods (Access = private)
    function delete(myself)
    % Turns off the laser
      myself.SetPower(0);
    end
  end
end

