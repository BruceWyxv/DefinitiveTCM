classdef ImageToggle
% Controls a GUI element with on/off states and associated images
%
% Simplifies the initialization and control of a toggle element in a GUI
% that has a custom image for the on/off states
  
  properties (SetAccess = private, GetAccess = public);
    on; % Current state of the control
  end
  
  properties (SetAccess = immutable, GetAccess = private);
    control; % Handle to the uicontrol that is modified by this class
    onImage; % The 'on' image, scaled to the size of the control
    offImage; % The 'off' image, scaled to the size of the control
  end
  
  methods
    function myself = ImageToggle(control, onImageFile, offImageFile, keepAspectRatio)
    % Construct this class and generate the images
      if nargin == 3
        keepAspectRatio = false;
      end
      
      % Set the class parameters
      myself.control = control;
      
      % Get the background color of the control for blending purposes
      background = uint8(get(control, 'color') * 255);
      
      % Load the image files
      [fullImageOn, ~, fullAlphaOn] = imread(onImageFile);
      [fullImageOff, ~, fullAlphaOff] = imread(offImageFile);
      
      % Perform the alpha blending
      imageProcessing = Images();
      compositeOn = imageProcessing.CompositeAlphaOverSolid(fullImageOn, fullAlphaOn, background);
      compositeOff = imageProcessing.CompositeAlphaOverSolid(fullImageOff, fullAlphaOff, background);
      
      % Scale the image to the control size
      position = getpixelposition(control);
      width = position(3);
      height = position(4);
      myself.onImage = imageProcessing.Resize(compositeOn, 'height', height, 'width', width', 'keepAspect', keepAspectRatio);
      myself.offImage = imageProcessing.Resize(compositeOff, 'height', height, 'width', width', 'keepAspect', keepAspectRatio);
      
      % Set the control to the 'off' state by default
      myself.SetState(false);
    end
    
    function SetState(myself, state)
    % Set the LED to 'on' for true, 'off' for false
      if state
        image = myself.onImage;
      else
        image = myself.offImage;
      end
      
      set(myself.control, 'CData', image);
    end
  end
  
end

