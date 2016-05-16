function LookAndFeel()
% Ensure that the program looks like it should, downloaded and modified
% from http://www.mathworks.com/support/bugreports/license/accept_license/6705?fname=startup.zip&geck_id=1293244
  if isdeployed && usejava('swing')
    [major, minor] = mcrversion;
    if major == 9 && minor == 0
      if ispc
        javax.swing.UIManager.setLookAndFeel('com.sun.java.swing.plaf.windows.WindowsLookAndFeel');
      elseif isunix
        javax.swing.UIManager.setLookAndFeel('com.jgoodies.looks.plastic.Plastic3DLookAndFeel');
      elseif ismac
        javax.swing.UIManager.setLookAndFeel('com.apple.laf.AquaLookAndFeel');
      end
    end
  end
end