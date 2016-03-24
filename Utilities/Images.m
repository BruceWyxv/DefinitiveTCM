% File:         Images.m
% Author:       Brycen Wendt (brycen.wendt@inl.gov; wendbryc@isu.edu)
% Date Created: 02/19/2015
%
% Usage:        handle        = Utilities()
%               %fileName      = <handle>.GetFileName(<directory>, <base>, <index>)
%               %specificHeat  = <handle>.GetSpecificHeat(<material>)
%               %              = <handle>.GetSpecificHeat(<thermalProps>)
%               %data          = <handle>.LoadData(<directory>, <base>, <count>)
% Inputs:       %<base>          Base of the file name, used to construct the
%               %                file name as <base>All<index>.mat
%               %<count>         Number of frequency sets to load when loading
%               %                data
%               %<directory>     Absolute path of the data file directory
%               %<handle>        Object handle to the utilities object
%               %<index>         Index number of the frequency set being
%               %                requested
%               %<material>      String name of material as it appears in the
%               %                database
%               %<thermalProps>  Structure of material, k, d, and rho
% Outputs:      %fileName        Absolute path to the TCM data file
%               handle          Object handle to the database object
%               %specificHeat    Specific heat of the requested material
%
% Description:  The images file is a basic collection of image processing tools
%               that can be leveraged anywhere within the Definitive TCM code.

function handle = Images()
% Assign the function handles
  handle.CompositeAlphaOverSolid = @CompositeAlphaOverSolid;
  handle.Resize = @Resize;
  handle.LanczosWindow = @LanczosKernel;
end


function composite = CompositeAlphaOverSolid(RGB, alpha, backgroundColor)
% Return a composite of an RGB image, with an associated alpha map,
% blended into a solid background color.
  mapSize = size(alpha);

  % Convert everything to doubles and reduce to a 0.0 to 1.0 scale
  RGB = double(RGB);
  alpha = im2double(alpha);

  % Perform the compositing
  background = zeros(mapSize);
  for i = 1:3
    background(:,:) = backgroundColor(i);
    RGB(:,:,i) = (RGB(:,:,i) .* alpha) + (background .* (1 - alpha));
  end
  
  % Convert to the required image data ranges
  % This is a safe conversion, as uint8() caps data values to the range
  % 0--255 without wrap-around. Anything less that 0 will be collapsed to
  % 0, and anything greater than 255 will be collapsed to 255.
  composite = uint8(RGB);
end


function scaled = Resize(original, varargin)
% Resize an image according the input arguments

  % Define the input arguments
  parser = inputParser;
  parser.addRequired('original', @(x) validateattributes(x, {'numeric'}, {'ndims', 3}));
  parser.addOptional('height', -1, @(x) validateattributes(x, {'numeric'}, {'scalar'}));
  parser.addOptional('width', -1, @(x) validateattributes(x, {'numeric'}, {'scalar'}));
  parser.addParameter('scale', 0, @(x) validateattributes(x, {'numeric'}, {'scalar'}, {'nonnegative'}));
  parser.addParameter('keepAspect', false, @(x) validateattributes(x, {'logical'}, {'scalar'}));
  defaultMethod = 'lanczos';
  parser.addParameter('method', defaultMethod, @ischar);

  % Check the input arguments
  parser.KeepUnmatched = true;
  try
    parser.parse(original, varargin{:});
  catch me
    errorString = ['Error when trying to parse input arguments:   ' me.message];
    error(errorString);
  end
  if ~isempty(fieldnames(parser.Unmatched))
    warning('MATLAB:unknownArgument', 'Some arguments were not recognized:');
    disp(parser.Unmatched);
  end

  % Get additional input parameters
  height = parser.Results.height;
  width = parser.Results.width;
  scale = parser.Results.scale;
  keepAspect = parser.Results.keepAspect;
  method = parser.Results.method;

  % Sanitize the inputs
  matrixSize = size(original); % Get the number of rows and columns
  originalHeight = matrixSize(1); % The number of rows equals the height
  originalWidth = matrixSize(2); % The number of columns equals the width
  originalSize = [originalWidth originalHeight];
  
  % Determine the new size of the image
  if keepAspect && scale == 0 % keepAspect is implied if 'scale' is specified
    % Determine which size specification will bound the new image size
    heightRatio = double(height) / originalHeight;
    widthRatio = double(width) / originalWidth;
    if xor(height < 0, width < 0)
      % Only one dimension was provided, so set both ratios to the positive
      % value
      if height < 0
        heightRatio = widthRatio;
      else
        widthRatio = heightRatio;
      end
    elseif height < 0 && width < 0
      % No values were provided
      error('You must specify at least one of "height" or "width" with the "keepAspect" key set to "true".')
    end
    % Set the sizes
    if heightRatio < widthRatio
      % Limited by the height
      newSize = originalSize * heightRatio;
    else
      % Limited by width
      newSize = originalSize * widthRatio;
    end
  elseif scale > 0
    newSize = originalSize * scale;
  else
    if height < 0
      height = originalHeight;
    end
    if width < 0
      width = originalWidth;
    end
    newSize = [width, height];
  end
  
  newSize = round(newSize);
  switch lower(method)
    case 'lanczos'
      scaled = Lanczos(original, newSize);
    otherwise
      warning('MATLAB:unknownMethod', ['Method ' method ' is not recognized. Defaulting to ' defaultMethod '.']);
      scaled = Resize(original, 'width', newSize(1), 'height', newSize(2),  'keepAspect', false);
  end
end


function scaled = Lanczos(original, newSize)
% Resize an image using the Lancsoz method. In many cases this is
% considered superior to bicubic sampling, although at a slight performance
% cost.

  % We will use a value of 3 for the filter size
  filterSize = 3;
  
  % Convert the image to double values in the range 0.0-1.0
  original = double(original) / 255;
  oldMatrixSize = size(original);
  % Again, the number of rows equals the height, and the number of columns
  % equals the width
  oldSize = [oldMatrixSize(2) oldMatrixSize(1)];
  
  % Scale the width
  rowScaled = zeros(oldSize(2), newSize(1), 3);
  for i = 1:oldSize(2)
    rowScaled(i,:,:) = Lanczos1D(original(i,:,:), newSize(1), filterSize);
  end
  
  % Scale the height
  swapRowsAndColumns = @(array) permute(array, [2, 1, 3]);
  scaled = zeros(newSize(2), newSize(1), 3);
  for i = 1:newSize(1)
    scaled(:,i,:) = swapRowsAndColumns(Lanczos1D(swapRowsAndColumns(rowScaled(:,i,:)), newSize(2), filterSize));
  end
  
  scaled = uint8(scaled * 255);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Private functions not exposed outside this .m file %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scaledRow = Lanczos1D(row, newSize, filterSize)
  oldSize = length(row);
  sum = zeros(1, newSize, 3);
  weight = zeros(1, newSize, 3);
  ratio = double(oldSize) / newSize;
  
  % Iterate over all the columns
  for newIndex = 1:(newSize)
    x = (newIndex) * ratio;
    floorX = floor(x);
    filter = zeros(3,1);
    
    % Collapse or expand the RGB data in one direction
    for i = (floorX - filterSize + 1):(floorX + filterSize)
      if i >= 1 && i <= oldSize
        for color = 1:3
          filter(color) = LanczosKernel(x - i, filterSize);
          sum(1,newIndex,color) = sum(1,newIndex,color) + row(1,i,color) * filter(color);
          weight(1,newIndex,color) = weight(1,newIndex,color) + filter(color);
        end
      end
    end
  end
  
  % Normalize everything
  scaledRow = sum ./ weight;
end


function result = LanczosKernel(x, filterSize)
% Apply the Lanczos window
  if abs(x) < filterSize
    if x == 0
      result = 1.0;
    else
      product = x * pi;
      result = (filterSize * sin(product) * sin(product / filterSize)) / (product * product);
    end
  else
    result = 0.0;
  end
end
