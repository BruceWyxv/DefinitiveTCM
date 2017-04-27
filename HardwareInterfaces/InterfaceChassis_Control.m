classdef InterfaceChassis_Control < RS232_Interface
% Provides commands for interfacing with the interface chassis controller
%
%   Control of the interface chassis controller is simplified via
%   implementation of the required commands and class member functions

  properties (Constant = true, GetAccess = public)
    powerToggleSequence = [char(27), char(2)]; % Command to toggle channels
  end
  
  properties (SetAccess = private, GetAccess = public)
    channelStates; % Each bit represents the off/on state of the corresponding channel
  end
  
  methods
    function myself = InterfaceChassis_Control(name)
    % Construct this class and call the superclass constructor to intialize
    % the interface to the device
      if nargin == 1
        name = InterfaceChassis_Control.GetUnknownDeviceName();
      end
      myself@RS232_Interface('COM1', name);
      
      % Prepare the device for communications
      myself.ActiveOff();
      % Enable computer control of port 'AC'
      RS232_Interface.Communicate(myself, [myself.powerToggleSequence, 'AC'])
    end
    
    function EnableChannel(myself, channelHex)
    % Turn on a specific channel, even if it is already on
      if ischar(channelHex)
        channel = hex2dec(channelHex);
      else
        channel = channelHex;
      end
      channel = channel + 1;
      
      myself.SetChannels(channel, 1)
    end
    
    function DisableChannel(myself, channelHex)
    % Turn off a specific channel, even if it is already off
      if ischar(channelHex)
        channel = hex2dec(channelHex);
      else
        channel = channelHex;
      end
      channel = channel + 1;
      
      myself.SetChannels(channel, 0)
    end
    
    function states = ReadStates(myself)
    % Read the current channel states
      states = RS232_Interface.Communicate(myself, '!0RD', 2);
      myself.channelStates = states;
    end
    
    function SetChannels(myself, channels, states)
    % Sets the specified channels to the specified value
      currentStates = myself.ReadStates();
      First8 = uint8(currentStates(2));
      Last8 = uint8(currentStates(1));
      
      for i = 1:length(channels)
        channel = channels(i);
        state = states(i);
        
        if channel < 9
          First8 = bitset(First8, channel, state, 'uint8');
        else
          Last8 = bitset(Last8, channel - 8, state, 'uint8');
        end
      end
      
      RS232_Interface.Communicate(myself, ['!0SO', char(Last8), char(First8)]);
    end
    
    function ToggleChannels(myself, channels)
    % Toggle the state of a channel
      currentStates = myself.ReadStates();
      First8 = uint8(currentStates(2));
      Last8 = uint8(currentStates(1));
      
      for i = 1:length(channels)
        channel = channels(i);
        
        if channel < 9
          First8 = bitset(First8, channel, ~bitget(First8, channel, 'uint8'), 'uint8');
        else
          Last8 = bitset(Last8, channel - 8, ~bitget(Last8, channel - 8, 'uint8'), 'uint8');
        end
      end
      
      RS232_Interface.Communicate(myself, ['!0SO', char(Last8), char(First8)]);
    end
  end
  
  methods (Access = private)
    function ActiveOff(myself)
    % Turn off all the serial ports
      RS232_Interface.Communicate(myself, [myself.powerToggleSequence, char(4)]);
    end
    
    function delete(myself)
    % Prepare the class for deletion by turning off the active port
      myself.ActiveOff();
    end
  end
end

