gpib = ESP300_Control(16);
for axis = 1:3
  fprintf('\n\n\n==============%i==================\n', axis);
  gpib.Command(axis, 'OR');
  motionCompleted = 0;
  while ~motionCompleted
    pause(.030);
    fprintf('%g\n', str2double(gpib.Query(axis, 'TP')));
    motionCompleted = str2double(gpib.Query(axis, 'MD'));
  end
end
clear