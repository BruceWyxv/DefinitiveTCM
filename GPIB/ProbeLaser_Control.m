classdef ProbeLaser_Control
  %PROBELASER_CONTROL Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (SetAccess = immutable, GetAccess = protected)
    lockInAmpControl; % Handle to the lock-in amplifier, which is used to control power to the probe laser
    probeControlOutputIndex; % Index of the output that is used to control the laser
  end
  
  methods
    function myself = ProbeLaser_Control(lockInAmpControl, probeControlOutputIndex)
    % Construct this class
      if ~isa(lockInAmpControl, 'SR830_Control')
        error('Must provide a valid handle to the lock-in amplifier controller.');
      end
      
      myself.lockInAmpControl = lockInAmpControl;
      myself.probeControlOutputIndex = probeControlOutputIndex;
    end
    
    function TurnOff()
      myself.lockInAmpControl.SetAuxOutputVoltage(myself.probeControlOutputIndex, 0);
    end
    
    function TurnOn()
      myself.lockInAmpControl.SetAuxOutputVoltage(myself.probeControlOutputIndex, 10);
    end
  end
  
  methods (Access = private)
    function delete(myself)
    % Turn off the laser before the class is deleted
      myself.TurnOff();
    end
  end
end

