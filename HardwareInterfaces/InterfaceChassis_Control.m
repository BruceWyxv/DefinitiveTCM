classdef InterfaceChassis_Control < RS232_Interface
% Provides commands for interfacing with the interface chassis controller
%
%   Control of the interface chassis controller is simplified via
%   implementation of the required commands and class member functions
%   Channel   Connected device
%   --------------------------
%      0      Interlock (DON'T TOUCH!!!)
%      1      Interlock (DON'T TOUCH!!!)
%      2      TCM detector power
%      3      Sample position and scan camera powers
%      4      Load position camera power
%      5      LED on for ?scan location
%      6      LED on for ?position location
%      7      Turn on probe laser photo diode diagnostic
%      8      Turn on pump laser power photo diode diagnostic
%      9      Lock-In amp signal coupling
%                 Off -> AC
%                 On  -> DC
%      A      Slot detector power
%      B      Thickness measurement photo diode power
%      C      Switch Lock-in Amp signal source
%                 Off -> Thermal conductivity measurements
%                 On  -> Film thickness transmission measurements
%      D      Switch for the laser being driven by the fuction generator
%                 Off -> 660 nm for thermal conductivity measurements
%                 On  -> 488 nm for film thickness measurements
%      E      --
%      F      --

  properties (Constant = true, GetAccess = public)
    commandPortSwitch = [char(27), char(2)]; % Command to access port switch
    allPortsOff = char(4); % Command to turn off all ports on the port switch
    interfaceSwitchPort = 'AC';
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
      RS232_Interface.Communicate(myself, [myself.commandPortSwitch, myself.interfaceSwitchPort]);
    end
    
    function ConfigureForAllOff(myself)
    % Turns everything off
    % system
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON                                                               
    %    OFF  X   X   X   X   X   X   X   X   X       X   X                
    % IGNORE                                      X           X   X   X   X
      set   =[0,  1,  2,  3,  4,  5,  6,  7,  8,     'A','B'               ];
      state =[0,  0,  0,  0,  0,  0,  0,  0,  0,      0,  0                ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForFilmThickness(myself)
    % Configure the channels for use with the film thickness measurement
    % system
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X                                       X   X   X        
    %    OFF          X   X   X   X   X   X   X   X   X                    
    % IGNORE                                                          X   X
      set   =[0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 'A','B','C','D'       ];
      state =[1,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1        ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForManualDiagnostic(myself)
    % Configure the channels to perform manual diagnostics on the laser
    % powers
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X                       X   X                            
    %    OFF                                                               
    % IGNORE          X   X   X   X   X           X   X   X   X   X   X   X
      set   =[0,  1,                      7,  8                            ];
      state =[1,  1,                      1,  1                            ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForNothing(myself)
    % Sets the system to a state for not using anything
    % system
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X                                                        
    %    OFF          X   X   X   X   X   X   X       X   X                
    % IGNORE                                      X           X   X   X   X
      set   =[0,  1,  2,  3,  4,  5,  6,  7,  8,     'A','B'               ];
      state =[1,  1,  0,  0,  0,  0,  0,  0,  0,      0,  0                ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForPositionSampleLoad(myself)
    % Configure the system electronics for loading a sample onto the stage
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X           X                                            
    %    OFF                              X   X   X       X   X   X        
    % IGNORE          X   X       X   X               X               X   X
      set   =[0,  1,          4,          7,  8,  9,     'B','C','D'       ];
      state =[1,  1,          1,          0,  0,  0,      0,  0,  0        ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForPositionScan(myself)
    % Configure the inputs for collecting data
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X   X   X       X                                        
    %    OFF                              X   X   X       X   X   X        
    % IGNORE                  X       X               X               X   X
      set   =[0,  1,  2,  3,      5,      7,  8,  9,     'B','C','D'       ];
      state =[1,  1,  1,  1,      1,      0,  0,  0,      0,  0,  0        ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForPositionWideImage(myself)
    % Configure the system electronics for vieweing at the wide angle
    % position
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X       X           X                                    
    %    OFF                              X   X   X       X   X   X        
    % IGNORE          X       X   X                   X               X   X
      set   =[0,  1,      3,          6,  7,  8,  9,     'B','C','D'       ];
      state =[1,  1,      1,          1,  0,  0,  0,      0,  0,  0        ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForPositionUnknown(myself)
    % Set the system for a general unknown state that will not hurt
    % anything if it is left like this indefinitely
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X       X   X   X   X                                    
    %    OFF                              X   X   X       X   X   X        
    % IGNORE          X                               X               X   X
      set   =[0,  1,      3,  4,  5,  6,  7,  8,  9,     'B','C','D'       ];
      state =[1,  1,      1,  1,  1,  1,  0,  0,  0,      0,  0,  0        ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForProbePowerDiagnostic(myself)
    % Configure the channels to measure the return power of the probe laser
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X   X   X       X               X                        
    %    OFF                                              X   X   X        
    % IGNORE                  X       X   X   X       X               X   X
      set   =[0,  1,  2,  3,      5,              9,     'B','C','D'       ];
      state =[1,  1,  1,  1,      1,              1,      0,  0,  0        ];
      myself.SetChannels(set, state);
    end
    
    function ConfigureForSampleHeightMeasurement(myself)
    % Configure the channels to find the sample height using the slot
    % detector
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON  X   X                                   X                    
    %    OFF                                                               
    % IGNORE          X   X   X   X   X   X   X   X       X   X   X   X   X
      set   =[0,  1,                                 'A'                   ];
      state =[1,  1,                                  1                    ];
      myself.SetChannels(set, state);
    end
    
    function states = ReadStates(myself)
    % Read the current channel states
      states = RS232_Interface.Communicate(myself, '!0RD', 2);
      myself.channelStates = states;
    end
    
    function SetIllumination(myself, tf)
    % Turn on/off the lighting LEDs
    %  State  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    %     ON                      X   X                                    
    %    OFF                                                               
    % IGNORE  X   X   X   X   X           X   X   X   X   X   X   X   X   X
      set   =[                    5,  6                                    ];
      state =[                    tf, tf                                   ];
      myself.SetChannels(set, state);
    end
  end
  
  methods (Access = private)
    function ActiveOff(myself)
    % Turn off all the serial ports
      RS232_Interface.Communicate(myself, [myself.commandPortSwitch, myself.allPortsOff]);
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
    
    function SetChannels(myself, channelHexes, states)
    % Sets the specified channels to the specified value
      currentStates = myself.ReadStates();
      First8 = uint8(currentStates(2));
      Last8 = uint8(currentStates(1));
      
      for i = 1:length(channelHexes)
        channelHex = channelHexes(i);
        if ischar(channelHex)
          if channelHex <= 9
            channel = uint8(channelHex);
          else
            channel = hex2dec(channelHex);
          end
        else
          channel = channelHex;
        end
        channel = channel + 1;
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
    
    function delete(myself)
    % Prepare the class for deletion by turning off the active port
      myself.ActiveOff();
    end
  end
end

