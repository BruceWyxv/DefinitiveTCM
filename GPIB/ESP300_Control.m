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
      for i = 1:length(varagin)
        pause(varargin{i}(1));
        myself.PreserveOldCommandAndReply(true);
        myself.SendCommand('99PA0.0');
      end
    end
  end
end

