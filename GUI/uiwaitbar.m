function h = uiwaitbar(varargin)
%uiwaitbar: A waitbar that can be embedded in a GUI figure.
% Syntax:
% POSITION = [20 20 200 20]; % Position of uiwaitbar in pixels.
% H = uiwaitbar(POSITION);
% for i = 1:100
% uiwaitbar(H,i/100)
% end
 
% written by Doug Schwarz, 11 December 2008
% modified by Brycen Wendt
 
  if ischar(varargin{1})
    command = lower(varargin{1});
    switch command
      case 'create'
        h = Create(varargin{2}, varargin{3});
        
      case 'update'
        Update(varargin{2}, varargin{3});
        
      case 'get'
        waitbar = get(varargin{2}, 'Child');
        data = get(waitbar, 'XData');
        h = data(3);
    end
  else
    Update(varargin{1}, varargin{2});
  end
end

function waitbar = Create(parent, position)
  backgroundColor = 'w';
  foregroundColor = 'g';
  waitbar = axes('Parent', parent,...
                 'Units', 'pixels',...
                 'Position', position,...
                 'XLim', [0 1], 'YLim', [0 1],...
                 'XTick', [], 'YTick', [],...
                 'Color', backgroundColor,...
                 'XColor', backgroundColor, 'YColor', backgroundColor);
  patch([0 0 0 0], [0 1 1 0], foregroundColor,...
        'Parent', waitbar,...
        'EdgeColor', 'none');
end

function Update(waitbar, value)
  bar = get(waitbar, 'Child');
  data = get(bar, 'XData');
  data(3:4) = value;
  set(bar, 'XData', data)
  return
end
