function [] = stk2tiff(stk,filename,pathname,header)
%A function to save a matrix as a tiff stack.
%Synatax: stk2tiff(stk)
%Input: stk = a matrix of images.
%       filename = the name of the file.
%       pathname = the path of the file to be saved.
%Output: Other than the file series, no outputs.

[x,y,d,z] = size(stk);    %get the size of the image stack.

%where do you want to save it?
if nargin==1    %no explicit directory
    [filename,pathname,filterindex] = uiputfile2('.tif');
end
%remove the file type if needed
if strcmp('.',filename(1,end-3)) || strcmp('.',filename(1,end-4))  %note this recognizes '.tiff', but leaves the '.'
    filename = filename(1:end-4);   %remove the file type first
end
%prepare to output other classes of images
imgclass = class(stk);      %get image type

%create the tag structure for the tiff image
tagstruct.ImageLength = y;
tagstruct.ImageWidth = x;
tagstruct.Photometric = 1;      %min is black
switch imgclass     %for now we only traffic in 16bit and 32bit tiffs
    case 'uint32'
        tagstruct.BitsPerSample = 32;   %32bit
    otherwise
        tagstruct.BitsPerSample = 16;   %16bit
        stk = im2uint16(stk);
end
tagstruct.SamplesPerPixel = 2;
tagstruct.RowsPerStrip = 2;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB';
tagstruct.ImageDescription = header;

%now save stack as a series of images
warning('OFF')
%h2 = waitbar(0,['Saving Image: ',num2str(1),' to ',pathname,filename,'.tif']);    %initialize progress bar.
%parallelize
%matlabpool      %initiate processes

 h = Tiff([pathname,filename,'.tif'],'w');  
 h.setTag(tagstruct); 
for i = 1:z
    %save the file with 00 padding
%    if i<10   %double pad
%        h = Tiff([pathname,filename,'_00',num2str(i),'.tif'],'w');    %open tiff object
%    elseif i<100  %single pad
%        h = Tiff([pathname,filename,'_0',num2str(i),'.tif'],'w');    %open tiff object
%    else        %no pad
%        h = Tiff([pathname,filename,'_',num2str(i),'.tif'],'w');    %open tiff object
%    end
               %set the tag structure
    %h.write(uint16(stk(:,:,i))'); %write the image & rotate it to video coordinates
    h.write(stk(:,:,:,i)); %write the image & rotate it to video coordinates
    %close(h);                       %close the file
    %waitbar(i/z,h2,['Saving Image: ',num2str(i+1),' to
    %',pathname,filename,'.tif']);   %update progress
end
%matlabpool close %close processes
close(h)
warning('ON')