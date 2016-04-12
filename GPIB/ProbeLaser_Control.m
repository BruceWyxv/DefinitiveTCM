classdef ProbeLaser_Control < handle
% Provides commands for controlling the probe laser
  
  properties (SetAccess = immutable, GetAccess = protected)
    lockInAmpControl; % Handle to the lock-in amplifier, which is used to control power to the probe laser
    probeControlOutputIndex; % Index of the output that is used to control the laser
  end
  
  properties (SetAccess = private, GetAccess = public)
    isOn; % Boolean state for if the laser is on
  end
  
  methods
    function myself = ProbeLaser_Control(lockInAmpControl, probeControlOutputIndex)
    % Construct this class
      if ~isa(lockInAmpControl, 'SR830_Control')
        error('Must provide a valid handle to the lock-in amplifier controller.');
      end
      
      myself.lockInAmpControl = lockInAmpControl;
      myself.isOn = false;
      myself.probeControlOutputIndex = probeControlOutputIndex;
    end
    
    function TurnOff(myself)
      myself.lockInAmpControl.SetAuxOutputVoltage(myself.probeControlOutputIndex, 0);
      myself.isOn = false;
    end
    
    function TurnOn(myself)
      myself.lockInAmpControl.SetAuxOutputVoltage(myself.probeControlOutputIndex, 10);
      myself.isOn = true;
    end
  end
  
  methods (Access = private)
    function delete(myself)
    % Turn off the laser before the class is deleted
      myself.TurnOff();
    end
  end
end

