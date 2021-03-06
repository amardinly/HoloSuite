% TIFFStack - Manipulate a TIFF file like a tensor
% 
% Usage: tsStack = TIFFStack(strFilename <, bInvert>)
% 
% A TIFFStack object behaves like a read-only memory mapped TIF file.  The
% entire image stack is treated as a matlab tensor.  Each frame of the file must
% have the same dimensions.  Reading the image data is optimised to the extent
% possible; the header information is only read once.
%
% If this software is useful to your academic work, please cite our
% publication in lieu of thanks:
%
% D R Muir and B M Kampa, 2015. "FocusStack and StimServer: a new open
%    source MATLAB toolchain for visual stimulation and analysis of two-photon
%    calcium neuronal imaging data". Frontiers in Neuroinformatics 8 (85).
%    DOI: 10.3389/fninf.2014.00085
% 
% This class attempts to use the version of tifflib built-in to recent
% versions of Matlab, if available.  Otherwise this class uses a modified
% version of tiffread [1, 2] to read data.
%
% permute, ipermute and transpose are now transparantly supported. Note
% that to read a pixel, the entire frame containing that pixel is read. So
% reading a Z-slice of the stack will read in the entire stack.
% 
% Construction:
% 
% >> tsStack = TIFFStack('test.tiff');       % Construct a TIFF stack associated with a file
% 
% >> tsStack = TIFFStack('test.tiff', true); % Indicate that the image data should be inverted
% 
% tsStack = 
% 
%   TIFFStack handle
% 
%   Properties:
%          bInvert: 0
%      strFilename: [1x9 char]
%       sImageInfo: [5x1 struct]
%     strDataClass: 'uint16'
% 
% Usage:
% 
% >> tsStack(:, :, 3);     % Retrieve the 3rd frame of the stack, all planes
% 
% >> tsStack(:, :, 1, 3);  % Retrieve the 3rd plane of the 1st frame
% 
% >> size(tsStack)         % Find the size of the stack (rows, cols, frames, planes per pixel)
% 
% ans =
% 
%    128   128     5     1
% 
% >> tsStack(4);           % Linear indexing is supported
% 
% >> tsStack.bInvert = true;  % Turn on data inversion
% 
% References:
% [1] Francois Nedelec, Thomas Surrey and A.C. Maggs. Physical Review Letters
%        86: 3192-3195; 2001. DOI: 10.1103/PhysRevLett.86.3192
% 
% [2] http://www.embl.de/~nedelec/

% Author: Dylan Muir <muir@hifo.uzh.ch>
% Created: 28th June, 2011

classdef TIFFStack < handle
   properties
      bInvert;             % - A boolean flag that determines whether or not the image data will be inverted
   end
   
   properties (SetAccess = private)
      strFilename = [];    % - The name of the TIFF file on disk
      sImageInfo;          % - The TIFF header information
      strDataClass;        % - The matlab class in which data will be returned
   end
   
   properties (SetAccess = private, GetAccess = private)
      vnDataSize;          % - Cached size of the TIFF stack
      TIF;                 % \_ Cached header infor for tiffread29 speedups
      HEADER;              % /
      bUseTiffLib;         % - Flag indicating whether TiffLib is being used
      fhReadFun;           % - When using Tiff class, function for reading data
      vnDimensionOrder;    % - Internal dimensions order to support permution
   end
   
   methods
      % TIFFStack - CONSTRUCTOR
      function oStack = TIFFStack(strFilename, bInvert)
         % - Check usage
         if (~exist('strFilename', 'var') || ~ischar(strFilename))
            help TIFFStack;
            error('TIFFStack:Usage', ...
                  '*** TIFFStack: Incorrect usage.');
         end
         
         % - Can we use the accelerated TIFF library?
         if (exist('tifflib') ~= 3) %#ok<EXIST>
            % - Try to copy the library
            strTiffLibLoc = which('/private/tifflib');
            strTIFFStackLoc = fileparts(which('TIFFStack'));
            copyfile(strTiffLibLoc, fullfile(strTIFFStackLoc, 'private'), 'f');
         end
         
         oStack.bUseTiffLib = (exist('tifflib') == 3); %#ok<EXIST>
         
         if (~oStack.bUseTiffLib)
            warning('TIFFStack:SlowAccess', ...
                    '--- TIFFStack: Using slower non-TiffLib access.');
         end
         
         % - Check for inversion flag
         if (~exist('bInvert', 'var'))
            bInvert = false;
         end
         oStack.bInvert = bInvert;
         
         % - See if filename exists
         if (~exist(strFilename, 'file'))
            error('TIFFStack:InvalidFile', ...
                  '*** TIFFStack: File [%s] does not exist.', strFilename);
         end
         
         % - Assign absolute file path to stack
         strFilename = get_full_file_path(strFilename);
         oStack.strFilename = strFilename;
         
         % - Get image information
         try
            % - Read and save image information
            sInfo = imfinfo(strFilename);
            oStack.sImageInfo = sInfo;

            if (oStack.bUseTiffLib)
               % - Create a Tiff object
               oStack.TIF = tifflib('open', strFilename, 'r');
               
               % - Check data format
               if(TiffgetTag(oStack.TIF, 'Photometric') == Tiff.Photometric.YCbCr)
                  error('TIFFStack:UnsupportedFormat', ...
                        '*** TIFFStack: YCbCr images are not supported.');
               end
               
               % - Use Tiff to get the data class for this tiff
               nDataClass = TiffgetTag(oStack.TIF, 'SampleFormat');
               switch (nDataClass)
                  case Tiff.SampleFormat.UInt
                     switch (sInfo(1).BitsPerSample(1))
                        case 1
                           oStack.strDataClass = 'logical';
                           
                        case 8
                           oStack.strDataClass = 'uint8';
                           
                        case 16
                           oStack.strDataClass = 'uint16';
                           
                        case 32
                           oStack.strDataClass = 'uint32';
                           
                        case 64
                           oStack.strDataClass = 'uint64';
                           
                        otherwise
                           error('TIFFStack:UnsupportedFormat', ...
                                 '*** TIFFStack: The sample format of this TIFF stack is not supported.');
                     end
                     
                  case Tiff.SampleFormat.Int
                     switch (sInfo(1).BitsPerSample(1))
                        case 1
                           oStack.strDataClass = 'logical';
                           
                        case 8
                           oStack.strDataClass = 'int8';
                           
                        case 16
                           oStack.strDataClass = 'int16';
                           
                        case 32
                           oStack.strDataClass = 'int32';
                           
                        case 64
                           oStack.strDataClass = 'int64';                           
                           
                        otherwise
                           error('TIFFStack:UnsupportedFormat', ...
                              '*** TIFFStack: The sample format of this TIFF stack is not supported.');
                     end
                     
                  case Tiff.SampleFormat.IEEEFP
                     switch (sInfo(1).BitsPerSample(1))
                        case {1, 8, 16, 32}
                           oStack.strDataClass = 'single';

                        case 64
                           oStack.strDataClass = 'double';
                           
                        otherwise
                           error('TIFFStack:UnsupportedFormat', ...
                              '*** TIFFStack: The sample format of this TIFF stack is not supported.');
                     end
                     
                  otherwise
                     error('TIFFStack:UnsupportedFormat', ...
                           '*** TIFFStack: The sample format of this TIFF stack is not supported.');
               end
               
               % - Assign accelerated reading function
               if (tifflib('isTiled', oStack.TIF))
                  if (isequal(TiffgetTag(oStack.TIF, 'PlanarConfiguration'), Tiff.PlanarConfiguration.Chunky))
                     oStack.fhReadFun = @TS_read_Tiff_tiled_chunky;
                     
                  elseif (isequal(TiffgetTag(oStack.TIF, 'PlanarConfiguration'), Tiff.PlanarConfiguration.Separate))
                     oStack.fhReadFun = @TS_read_Tiff_tiled_separate;
                  end
                  
               else
                  if (isequal(TiffgetTag(oStack.TIF, 'PlanarConfiguration'), Tiff.PlanarConfiguration.Chunky))
                     oStack.fhReadFun = @TS_read_Tiff_striped_chunky;
                     
                  elseif (isequal(TiffgetTag(oStack.TIF, 'PlanarConfiguration'), Tiff.PlanarConfiguration.Separate))
                     oStack.fhReadFun = @TS_read_Tiff_striped_separate;
                  end
               end
               
            else
               % - Read TIFF header for tiffread29
               [oStack.TIF, oStack.HEADER] = tiffread29_header(strFilename);

               % - Use tiffread29 to get the data class for this tiff
               fPixel = tiffread29_readimage(oStack.TIF, oStack.HEADER, 1);
               fPixel = fPixel(1, 1, :);
               oStack.strDataClass = class(fPixel);
            end
            
            % - Use imread to get the data class for this tiff
            % fPixel = imread(strFilename, 'TIFF', 1, 'PixelRegion', {[1 1], [1 1]});
            % oStack.strDataClass = class(fPixel);
            
            % - Record stack size
            oStack.vnDataSize = [sInfo(1).Height sInfo(1).Width numel(sInfo) sInfo(1).SamplesPerPixel];

            % - Initialise dimension order
            oStack.vnDimensionOrder = 1:numel(oStack.vnDataSize);

         catch mErr
            base_ME = MException('TIFFStack:InvalidFile', ...
                  '*** TIFFStack: Could not open file [%s].', strFilename);
            new_ME = addCause(base_ME, mErr);
            throw(new_ME);
         end
      end
      
      % delete - DESTRUCTOR
      function delete(oStack)
         if (oStack.bUseTiffLib)
            % - Close the TIFF file, if opened by TiffLib
            if (isfield(oStack, 'TIF') && ~isempty(oStack.TIF))
               tifflib('close', oStack.TIF);
            end

         else
            % - Close the TIFF file, if opened by tiffread29_header
            if (isfield(oStack.TIF, 'file'))
               fclose(oStack.TIF.file);
            end
         end
      end

%% --- Overloaded subsref

      function [tfData] = subsref(oStack, S)
         switch S(1).type
            case '()'
               nNumDims = numel(S.subs);
%                nNumStackDims = numel(oStack.vnDataSize);
               nNumTotalDims = numel(oStack.vnDimensionOrder);
               
               % - Inverse permute index order
               vnInvOrder(oStack.vnDimensionOrder(1:nNumTotalDims)) = 1:nNumTotalDims;
               
               % - Check dimensionality and trailing dimensions
               if (nNumDims == 1)
                  % - Translate colon indexing
                  if (isequal(S.subs{1}, ':'))
                     S.subs = num2cell(repmat(':', 1, nNumTotalDims));
                     nNumDims = 4;

                  else
                     % - Get equivalent subscripted indexes and permute
                     vnTensorSize = size(oStack);
                     [cIndices{1:nNumTotalDims}] = ind2sub(vnTensorSize, S.subs{1});
                     S.subs = cIndices(vnInvOrder);
                  end
                  
               elseif (nNumDims < nNumTotalDims)
                  % - Assume trailing references are ':'
                  S.subs(nNumDims+1:nNumTotalDims) = {':'};

                  % - Permute index order
                  S.subs = S.subs(vnInvOrder);
                  
               elseif (nNumDims == nNumTotalDims)
                  % - Simply permute and access tensor
                  
                  % - Permute index order
                  S.subs = S.subs(vnInvOrder);
                  
               else % (nNumDims > nNumTotalDims)
                  % - Check for non-colon references
                  vbNonColon = cellfun(@(c)(~ischar(c) | ~isequal(c, ':')), S.subs);
                  
                  % - Check only trailing dimensions
                  vbNonColon(1:nNumTotalDims) = false;
                  
                  % - Check trailing dimensions for non-'1' indices
                  if (any(cellfun(@(c)(~isequal(c, 1)), S.subs(vbNonColon))))
                     % - This is an error
                     error('TIFFStack:badsubscript', ...
                        '*** TIFFStack: Index exceeds stack dimensions.');
                  end
                  
                  % - Only keep relevant dimensions
                  S.subs = S.subs(1:nNumTotalDims);
                  
                  % - Permute index order
                  S.subs = S.subs(vnInvOrder);

                  % - Permute index order
                  S.subs = S.subs(vnInvOrder);
               end
               
               % - Access stack (tifflib or tiffread)
               if (oStack.bUseTiffLib)
                  tfData = TS_read_data_Tiff(oStack, S.subs, nNumDims == 1);
               else
                  tfData = TS_read_data_tiffread(oStack, S.subs, nNumDims == 1);
               end
               
               % - Permute dimensions, if linear indexing has not been used
               if (nNumDims > 1)
                  tfData = permute(tfData, oStack.vnDimensionOrder);
               end
               
               % - Reshape return data to concatenate trailing dimensions (just as
               % matlab does)
               if (nNumDims > 1) && (nNumDims < nNumTotalDims)
                  cnSize = num2cell(size(tfData));
                  tfData = reshape(tfData, cnSize{1:nNumDims-1}, []);
               end
               
            case '.'
               tfData = builtin('subsref', oStack, S);
               
            otherwise
               error('TIFFStack:InvalidReferencing', ...
                     '*** TIFFStack: Only ''()'' referencing is supported by TIFFStacks.');
         end
      end
      
%% --- Overloaded size, permute, ipermute, ctranspose, transpose
      function [varargout] = size(oStack, vnDimensions)
         % - Return the size of the stack, permuted
         vnSize = oStack.vnDataSize(oStack.vnDimensionOrder);
         
         % - Find last non-unitary dimension and trim
         nLastNonUnitary = find(vnSize == 1, 1, 'last') - 1;
         if (nLastNonUnitary < numel(vnSize))
            vnSize = vnSize(1:nLastNonUnitary);
         end
         
         % - Return specific dimension(s)
         if (exist('vnDimensions', 'var'))
            if (~isnumeric(vnDimensions) || any(vnDimensions < 1))
               error('TIFFStack:dimensionMustBePositiveInteger', ...
                  '*** TIFFStack: Dimensions argument must be a positive integer.');
            end
            
            vbExtraDimensions = vnDimensions > numel(vnSize);
            
            % - Return the specified dimension(s)
            vnSizeOut(~vbExtraDimensions) = vnSize(vnDimensions(~vbExtraDimensions));
            vnSizeOut(vbExtraDimensions) = 1;
         else
            vnSizeOut = vnSize;
         end
         
         % - Handle differing number of size dimensions and number of output
         % arguments
         nNumArgout = max(1, nargout);
         
         if (nNumArgout == 1)
            % - Single return argument -- return entire size vector
            varargout{1} = vnSizeOut;
            
         elseif (nNumArgout <= numel(vnSizeOut))
            % - Several return arguments -- return single size vector elements,
            % with the remaining elements grouped in the last value
            varargout(1:nNumArgout-1) = num2cell(vnSizeOut(1:nNumArgout-1));
            varargout{nNumArgout} = prod(vnSizeOut(nNumArgout:end));
            
         else %(nNumArgout > numel(vnSize))
            % - Output all size elements
            varargout(1:numel(vnSizeOut)) = num2cell(vnSizeOut);
            
            % - Deal out trailing dimensions as '1'
            varargout(numel(vnSizeOut)+1:nNumArgout) = {1};
         end
      end
      
      % permute - METHOD Overloaded permute function
      function [oStack] = permute(oStack, vnNewOrder)
         oStack.vnDimensionOrder(1:numel(vnNewOrder)) = oStack.vnDimensionOrder(vnNewOrder);
      end
      
      % ipermute - METHOD Overloaded ipermute function
      function [oStack] = ipermute(oStack, vnOldOrder)
         vnNewOrder(vnOldOrder) = 1:numel(vnOldOrder);
         oStack = permute(oStack, vnNewOrder);
      end
      
      % ctranspose - METHOD Overloaded ctranspose function
      function [oStack] = cstranspose(oStack)
         oStack = transpose(oStack);
      end
      
      % transpose - METHOD Overloaded transpose function
      function [oStack] = transpose(oStack)
         oStack = permute(oStack, [2 1]);
      end

%% --- Overloaded end

      function nLength = end(oStack, nEndDim, nTotalRefDims)
         vnSizes = size(oStack);
         if (nEndDim < nTotalRefDims)
            nLength = vnSizes(nEndDim);
         else
            nLength = prod(vnSizes(nEndDim:end));
         end
      end

%% --- Property accessors

      % set.bInvert - SETTER method for 'bInvert'
      function set.bInvert(oStack, bInvert)
         % - Check contents
         if (~islogical(bInvert) || ~isscalar(bInvert))
            error('TIFFStack:invalidArgument', ...
                  '*** TIFFStack/set.bInvert: ''bInvert'' must be a logical scalar.');
         else
            % - Assign bInvert value
            oStack.bInvert = bInvert;
         end
      end
      
   end
end

%% --- Helper functions ---

% TS_read_data_tiffread - FUNCTION Read the requested pixels from the TIFF file (using tiffread29)
%
% Usage: [tfData] = TS_read_data_imread(oStack, cIndices)
%
% 'oStack' is a TIFFStack.  'cIndices' are the indices passed in from subsref.
% Colon indexing will be converted to full range indexing.  cIndices is a cell
% array with the format {rows, cols, frames, slices}.  Slices are RGB or CMYK
% or so on.

function [tfData] = TS_read_data_tiffread(oStack, cIndices, bLinearIndexing)
   % - Convert colon indexing
   vbIsColon = cellfun(@(c)(ischar(c) & isequal(c, ':')), cIndices);
   
   for (nColonDim = find(vbIsColon))
      cIndices{nColonDim} = 1:oStack.vnDataSize(nColonDim);
   end
      
   % - Fix up subsample detection for unitary dimensions
   vbIsOne = cellfun(@(c)isequal(c, 1), cIndices);
   vbIsColon(~vbIsColon) = vbIsOne(~vbIsColon) & (oStack.vnDataSize(~vbIsColon) == 1);
   
   % - Check ranges
   vnMinRange = cellfun(@(c)(min(c)), cIndices);
   vnMaxRange = cellfun(@(c)(max(c)), cIndices);
   
   if (any(vnMinRange < 1) || any(vnMaxRange > oStack.vnDataSize))
      error('TIFFStack:badsubscript', ...
            '*** TIFFStack: Index exceeds stack dimensions.');
   end
   
   % - Find unique frames to read
   [vnFrameIndices, ~, vnOrigFrameIndices] = unique(cIndices{3});
   
   % - Read data block
   try
      tfDataBlock = tiffread29_readimage(oStack.TIF, oStack.HEADER, vnFrameIndices);
      
   catch mErr
      % - Record error state
      base_ME = MException('TIFFStack:ReadError', ...
         '*** TIFFStack: Could not read data from image file.');
      new_ME = addCause(base_ME, mErr);
      throw(new_ME);
   end
      
   % - Handle linear or subscript indexing
   if (~bLinearIndexing)
      % - Select pixels from frames, if necessary
      if any(~vbIsColon([1 2 4]))
         tfData = tfDataBlock(cIndices{1}, cIndices{2}, vnOrigFrameIndices, cIndices{4});
      else
         tfData = tfDataBlock;
      end

   else
      % - Convert frame indices to frame-linear
      vnFrameLinearIndices = sub2ind(oStack.vnDataSize([1 2 4]), cIndices{1}, cIndices{2}, cIndices{4});
      
      % - Allocate return vector
      tfData = zeros(numel(cIndices{1}), 1, oStack.strDataClass);

      % - Loop over images in stack and extract required frames
      for (nFrameIndex = 1:numel(vnFrameIndices))
         vbThesePixels = cIndices{3} == vnFrameIndices(nFrameIndex);
         mfThisFrame = tfDataBlock(:, :, nFrameIndex, :);
         tfData(vbThesePixels) = mfThisFrame(vnFrameLinearIndices(vbThesePixels));
      end
   end      
      
   % - Invert data if requested
   if (oStack.bInvert)
      tfData = oStack.sImageInfo(1).MaxSampleValue - (tfData - oStack.sImageInfo(1).MinSampleValue);
   end
end


% TS_read_data_Tiff - FUNCTION Read the requested pixels from the TIFF file (using tifflib)
%
% Usage: [tfData] = TS_read_data_Tiff(oStack, cIndices)
%
% 'oStack' is a TIFFStack.  'cIndices' are the indices passed in from subsref.
% Colon indexing will be converted to full range indexing.  cIndices is a cell
% array with the format {rows, cols, frames, slices}.  Slices are RGB or CMYK
% or so on.

function [tfData] = TS_read_data_Tiff(oStack, cIndices, bLinearIndexing)
   % - Convert colon indexing
   vbIsColon = cellfun(@(c)(ischar(c) & isequal(c, ':')), cIndices);
   
   for (nColonDim = find(vbIsColon))
      cIndices{nColonDim} = 1:oStack.vnDataSize(nColonDim);
   end

   % - Fix up subsample detection for unitary dimensions
   vbIsOne = cellfun(@(c)isequal(c, 1), cIndices);
   vbIsColon(~vbIsColon) = vbIsOne(~vbIsColon) & (oStack.vnDataSize(~vbIsColon) == 1);
   
   % - Check ranges
   vnMinRange = cellfun(@(c)(min(c)), cIndices);
   vnMaxRange = cellfun(@(c)(max(c)), cIndices);
   
   if (any(vnMinRange < 1) || any(vnMaxRange > oStack.vnDataSize))
      error('TIFFStack:badsubscript', ...
            '*** TIFFStack: Index exceeds stack dimensions.');
   end
   
   % - Get referencing parameters for TIF object
   w = oStack.vnDataSize(2);
   h = oStack.vnDataSize(1);
   rps = min(oStack.sImageInfo(1).RowsPerStrip, h);
   tw = min(oStack.sImageInfo(1).TileWidth, w);
   th = min(oStack.sImageInfo(1).TileLength, h);
   spp = oStack.sImageInfo(1).SamplesPerPixel;
   
   tlStack = oStack.TIF;

   % - Handle linear or subscript indexing
   if (~bLinearIndexing)
      % - Allocate single frame buffer
      vnBlockSize = oStack.vnDataSize(1:2);
      vnBlockSize(3) = numel(cIndices{3});
      vnBlockSize(4) = oStack.vnDataSize(4);
      tfImage = zeros([vnBlockSize(1:2) 1 vnBlockSize(4)], oStack.strDataClass);

      % - Allocate tensor for returning data
      vnOutputSize = cellfun(@(c)numel(c), cIndices);
      tfData = zeros(vnOutputSize, oStack.strDataClass);
      
      % - Do we need to resample the data block?
      bResample = any(~vbIsColon([1 2 4]));

      try
         % - Loop over images in stack
         for (nImage = 1:numel(cIndices{3}))
            % - Skip to this image in stack
            tifflib('setDirectory', tlStack, cIndices{3}(nImage)-1);
            
            % - Read data from this image, overwriting frame buffer
            [~, tfImage] = oStack.fhReadFun(tfImage, tlStack, spp, w, h, rps, tw, th, []);
            
            % - Resample frame, if required
            if (bResample)
               tfData(:, :, nImage, :) = tfImage(cIndices{1}, cIndices{2}, cIndices{4});
            else
               tfData(:, :, nImage, :) = tfImage;
            end
         end
         
      catch mErr
         % - Record error state
         base_ME = MException('TIFFStack:ReadError', ...
            '*** TIFFStack: Could not read data from image file.');
         new_ME = addCause(base_ME, mErr);
         throw(new_ME);
      end
           
   else
      % -- Linear indexing
      
      % - Allocate return vector
      tfData = zeros(numel(cIndices{1}), 1, oStack.strDataClass);
      
      % - Allocate single-frame buffer
      vnBlockSize = oStack.vnDataSize(1:2);
      vnBlockSize(3) = numel(cIndices{3});
      vnBlockSize(4) = oStack.vnDataSize(4);
      tfImage = zeros([vnBlockSize(1:2) 1 vnBlockSize(4)], oStack.strDataClass);
      
      % - Convert frame indices to frame-linear
      vnFrameLinearIndices = sub2ind(vnBlockSize([1 2 4]), cIndices{1}, cIndices{2}, cIndices{4});
      
      % - Loop over images in stack and extract required frames
      try
         for (nImage = unique(cIndices{3})')
            % - Find corresponding pixels
            vbThesePixels = cIndices{3} == nImage;
            
            % - Skip to this image in stack
            tifflib('setDirectory', tlStack, nImage-1);

            % - Read the subsampled pixels from the stack
            [tfData(vbThesePixels), tfImage] = oStack.fhReadFun(tfImage, tlStack, spp, w, h, rps, tw, th, vnFrameLinearIndices(vbThesePixels));
         end
         
      catch mErr
         % - Record error state
         base_ME = MException('TIFFStack:ReadError', ...
            '*** TIFFStack: Could not read data from image file.');
         new_ME = addCause(base_ME, mErr);
         throw(new_ME);
      end
   end
   
   % - Invert data if requested
   if (oStack.bInvert)
      tfData = oStack.sImageInfo(1).MaxSampleValue - (tfData - oStack.sImageInfo(1).MinSampleValue);
   end
end

% TS_read_Tiff_striped_separate - FUNCTION Read an image using tifflib, for
% striped separate TIFF files
function [vfOutputPixels, tfImageBuffer] = TS_read_Tiff_striped_separate(tfImageBuffer, tlStack, spp, ~, h, rps, ~, ~, vnFrameLinearIndices)
   for r = 1:rps:h
      row_inds = r:min(h,r+rps-1);
      for k = 1:spp
         stripNum = tifflib('computeStrip', tlStack, r-1, k-1);
         tfImageBuffer(row_inds,:,k) = tifflib('readEncodedStrip', tlStack, stripNum-1);
      end
   end
   
   % - Perform sub-referencing, if required
   if (~isempty(vnFrameLinearIndices))
      vfOutputPixels = tfImageBuffer(vnFrameLinearIndices);
   else
      vfOutputPixels = tfImageBuffer;
   end
end

% TS_read_Tiff_striped_chunky - FUNCTION Read an image using tifflib, for
% striped chunk TIFF files
function [vfOutputPixels, tfImageBuffer] = TS_read_Tiff_striped_chunky(tfImageBuffer, tlStack, ~, ~, h, rps, ~, ~, vnFrameLinearIndices)
   for r = 1:rps:h
      row_inds = r:min(h,r+rps-1);
      stripNum = tifflib('computeStrip', tlStack, r-1);
      tfImageBuffer(row_inds,:,:) = tifflib('readEncodedStrip', tlStack, stripNum-1);
   end
   
   % - Perform sub-referencing, if required
   if (~isempty(vnFrameLinearIndices))
      vfOutputPixels = tfImageBuffer(vnFrameLinearIndices);
   else
      vfOutputPixels = tfImageBuffer;
   end
end

% TS_read_Tiff_tiled_separate - FUNCTION Read an image using tifflib, for
% tiled separate TIFF files
function [vfOutputPixels, tfImageBuffer] = TS_read_Tiff_tiled_separate(tfImageBuffer, tlStack, spp, w, h, ~, tWidth, tHeight, vnFrameLinearIndices)
   for r = 1:tHeight:h
      row_inds = r:min(h,r+tHeight-1);
      for c = 1:tWidth:w
         col_inds = c:min(w,c+tWidth-1);
         for k = 1:spp
            tileNumber = tifflib('computeTile', tlStack, [r c]-1, k);
            tfImageBuffer(row_inds,col_inds,k) = tifflib('readEncodedTile', tlStack, tileNumber-1);
         end
      end
   end
   
   % - Perform sub-referencing, if required
   if (~isempty(vnFrameLinearIndices))
      vfOutputPixels = tfImageBuffer(vnFrameLinearIndices);
   else
      vfOutputPixels = tfImageBuffer;
   end
end

% TS_read_Tiff_tiled_chunky - FUNCTION Read an image using tifflib, for
% tiled chunky TIFF files
function [vfOutputPixels, tfImageBuffer] = TS_read_Tiff_tiled_chunky(tfImageBuffer, tlStack, ~, w, h, ~, tWidth, tHeight, vnFrameLinearIndices)
   for r = 1:tHeight:h
      row_inds = r:min(h,r+tHeight-1);
      for c = 1:tWidth:w
         col_inds = c:min(w,c+tWidth-1);
         tileNumber = tifflib('computeTile', tlStack, [r c]-1);
         tfImageBuffer(row_inds,col_inds,:) = tifflib('readEncodedTile', tlStack, tileNumber-1);
      end
   end
   
   % - Perform sub-referencing, if required
   if (~isempty(vnFrameLinearIndices))
      vfOutputPixels = tfImageBuffer(vnFrameLinearIndices);
   else
      vfOutputPixels = tfImageBuffer;
   end
end

function tagValue = TiffgetTag(oTiff,tagId)
% getTag  Retrieve tag from image.
%   tagValue = getTag(tagId) retrieves the value of the tag tagId
%   from the current directory.  tagId may be specified either via
%   the Tiff.TagID property or as a char string.
%
%   This method corresponds to the TIFFGetField function in the
%   LibTIFF C API.  To use this method, you must be familiar with
%   LibTIFF version 3.7.1 as well as the TIFF specification and
%   technical notes.  This documentation may be referenced at
%   <http://www.remotesensing.org/libtiff/document.html>.
%
%   Example:
%
%   t = Tiff('example.tif','r');
%   % Specify tag by tag number.
%   width = t.getTag(Tiff.TagID.ImageWidth);
%
%   % Specify tag by tag name.
%   width = t.getTag('ImageWidth');
%
%   See also setTag
%
%

   switch(class(tagId))
      case 'char'
         % The user gave a char id for the tag.
         tagValue = tifflib('getField',oTiff,Tiff.TagID.(tagId));
         
      otherwise
         % Assume numeric.
         tagValue = tifflib('getField',oTiff,tagId);
   end
end


% get_full_file_path - FUNCTION Calculate the absolute path to a given (possibly relative) filename
%
% Usage: strFullPath = get_full_file_path(strFile)
%
% 'strFile' is a filename, which may include relative path elements.  The file
% does not have to exist.
%
% 'strFullPath' will be the absolute path to the file indicated in 'strFile'.

function strFullPath = get_full_file_path(strFile)

   try
      fid = fopen(strFile);
      strFile = fopen(fid);
      
      [strDir, strName, strExt] = fileparts(strFile);
      
      if (isempty(strDir))
         strDir = '.';
         strFullDirPath = cd(cd(strDir));
         strFullPath = fullfile(strFullDirPath, [strName strExt]);
      else
         strFullPath = strFile;
      end
      
   catch mErr
      % - Record error state
      base_ME = MException('TIFFStack:ReadError', ...
         '*** TIFFStack: Could not open file [%s].', strFile);
      new_ME = addCause(base_ME, mErr);
      throw(new_ME);
   end
end
