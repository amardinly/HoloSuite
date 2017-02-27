function [ Setup, SLM, NiDaq ] = Load_Parameters(activateequipment)
%Pockel's Cell Channel and Properties Turn h to 1 to activate some%properties
if activateequipment == 1 %Mode for laser blinking only
    NiDaq=daq.createSession('ni');
    DeviceName = 'Dev1';
    NiDaq.addAnalogOutputChannel(DeviceName, 2, 'Voltage');                 %SATSUMA GAIN, first channel
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line4', 'OutputOnly' );      %SATSUMA GATE
    NiDaq.Rate = 30000;   
elseif activateequipment == 2 %Mode for acquisition of power measurement
    NiDaq=daq.createSession('ni');
    DeviceName = 'Dev1';
    NiDaq.addAnalogOutputChannel(DeviceName, 2, 'Voltage');                 %SATSUMA GAIN, first channel
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line4', 'OutputOnly' );      %SATSUMA GATE
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line2', 'OutputOnly' );      %CHECKED FlipNextHologram
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line3', 'OutputOnly' );      %CHECKED Restart sequence
    NiDaq.addAnalogInputChannel(DeviceName, 3, 'Voltage');                  %CHECKED %Reading Power from Power meter
    NiDaq.Rate = 30000;    
elseif activateequipment == 3 %Mode for acquisition of Spatial calibration
    NiDaq=daq.createSession('ni');
    DeviceName = 'Dev1';
    NiDaq.addAnalogOutputChannel(DeviceName, 2, 'Voltage');                 %SATSUMA GAIN, first channel
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line4', 'OutputOnly' );      %SATSUMA GATE
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line2', 'OutputOnly' );      %CHECKED FlipNextHologram
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line3', 'OutputOnly' );      %CHECKED Restart sequence
    NiDaq.addDigitalChannel(DeviceName, 'Port0/Line0', 'OutputOnly' );      %Scan image, send 5V pulse to activate scan image
    NiDaq.Rate = 30000;     
else
    NiDaq.Rate = 30000;       
end
                                                                                        %This is in hertz the sampling rate for generating timed outputs
locations = SatsumaRigFile();

Setup.TransferFolder =  locations.TransferFolder;%    '\\128.32.173.33\Imaging\STIM\Calibration TransferFolder';  %This is the folder where holograms are sent in and out
Setup.CalibrationFolder = locations.CalibrationParams;%  '\\128.32.173.33\Imaging\STIM\Calibration Parameters';      %This is the folder where Calibration data is stored
Setup.DisplayFolder =  locations.DisplayFolder;%    '\\128.32.173.33\Imaging\STIM\Calibration Displays';        %Folder for visual documentts about calibration (power curve, etc...)
Setup.ResultsFolder =       '\\128.32.173.33\Imaging\STIM\Results';                     %Folder for experiment results
Setup.SLMFolder = locations.SLMComputer;%     '\\128.32.173.33\Imaging\STIM\Calibration SLM Computer';    %Folder for transfer to SLM via ethernet
Setup.HoloRequestFolder = locations.HoloRequest; %  '\\128.32.173.33\Imaging\STIM\HoloRequest';                 %Folder for the listener
Setup.ScanImageFolder =   locations.ScanImageFolder;%  '\\128.32.173.33\Imaging\STIM\CalibrationScanimage';       
Setup.lambda = 1.042 ;                                                                  %Wavelength in microns
Setup.FPV = 5;                                                                         %Voltage for SATSUMA Gain
Setup.EOMCalibrationsteps = 60;                                                         %Number of global Calibration Steps
Setup.EOMCalibrationblinktime = 5; 
Setup.Ncycles = 6;


SLM.ScreenID = 1;      
SLM.X = 800;                                                                            %Pixel Count X axis
SLM.Y = 600;                                                                            %Pixel Count Y axis
SLM.subsampling = 2 ;                                                                   %Number subsampling for hologram computation
SLM.FocalFS = 200*1000;                                                                 %Focal length of the SLM's OFT.
SLM.pixelsizeX = 20;                                                                    %Pixel Sixe along X axis, In Microns
SLM.pixelsizeY = 20;                                                                    %Pixel Sixe along Y axis, In Microns Shortened by tilt angle
%SLM.Pixelmax = 238;   %Pixel for a 2Pi phase shift (To be Adjusted at 930)
SLM.Pixelmax = 210; %255   %Pixel for a 2Pi phase shift (To be Adjusted at 1040 nm)


% This estimates the intensity distribution on the SLM that is used to
% simulate hologram propagation and increase power. 
[UX,UY] = meshgrid(SLM.pixelsizeY*((1:SLM.X)-mean(1:SLM.X)),SLM.pixelsizeX*((1:SLM.Y)-mean(1:SLM.Y)));
SLM.sigmamicronX = 7000;
SLM.sigmamicronY = 5000;
SLM.GaussianBase = exp(-(UX.^2/SLM.sigmamicronX^2+UY.^2/SLM.sigmamicronY^2));



return

%Setup.USBport = 'com7';                             %Port for Sutter Controls
%Setup.FPV = -2;                                     %Full Power Voltage (To Be Adjusted, check sign and polarity on box)
%Setup.EOMCalibrationsteps = 50;                     %Number of Calibration Steps for Power Adjustments
%Setup.EOMCalibrationblinktime = 4;                  %Duration in seconds of each power claibration step for Power Adjustments
%Setup.lambda = 1.042 ;                              %Wavelength in microns
%Setup.GalvoPX= 512;                                 %Number of GalvoLines for COC
%Setup.GalvoPY = 512;                                %Number of GalvoColumns for COC

%Lens.objectif =         20;                         %Obejctif Magnification in X for 200 tube length
%Lens.tube =             200000;                     %Focal length of tube length in Microns
%Lens.two =              200000;                     %Focal length of Periscope lens after tube lens in microns
%Lens.three =            150000;                     %Focal length of Second periscope lens
%Setup.Magnification =   Lens.objectif*(Lens.tube/200000)*(Lens.three/Lens.two);     %Magnification of Real space from objective to Real space copy right before SLM (To be Adjusted)
%Setup.SLMLensFocal =    200000;                     %Focal length of lens directly behind SLM

%SLM Properties
%SLM.latencytime = 0.020;                %Time between fullscreen and actual image on SLM

%SLM.TiltAngle = 5*pi/180;               %SLM tilt angle (Half the angle between incoming beam and its reflection)


%SLM.ScreenID = 2;                       %Screen ID for fullscreen function
%SLM.FocalFS = 200*1000;                 %Focal length of the SLM's OFT.
%SLM.TetamaxX = (180/pi)*atan(Setup.lambda/(3*SLM.pixelsizeX));                      %Anglular deflection range in degrees from optical axis at slm
%SLM.TetamaxY = (180/pi)*atan(Setup.lambda/(3*SLM.pixelsizeY));
%SLM.RealWindowsizeX = 2*SLM.FocalFS*tan(pi*SLM.TetamaxX/180);                       %Window Size in Real Space right after SLM
%SLM.RealWindowsizeY = 2*SLM.FocalFS*tan(pi*SLM.TetamaxY/180);
%SLM.UX = linspace(-SLM.pixelsizeX*(SLM.X-1)/2,SLM.pixelsizeX*(SLM.X-1)/2,SLM.X);    %SLM Position vectors in Microns
%SLM.UY = linspace(-SLM.pixelsizeY*(SLM.Y-1)/2,SLM.pixelsizeY*(SLM.Y-1)/2,SLM.Y);    %SLM Position vectors in Microns
%[SLM.YY, SLM.XX] = meshgrid(SLM.UX,SLM.UY);                                         %SLM Position vectors in Microns

                                                             %Subsampling of the SLM for fourier computation (Integer)


%Display Properties here
%disp('With current parameters the reachable window has a size of : ')
%disp(strcat('Along the X axis : ',num2str(floor(SLM.RealWindowsizeX/Setup.Magnification)),' micrometers'))
%disp(strcat('Along the Y axis : ',num2str(floor(SLM.RealWindowsizeY/Setup.Magnification)),' micrometers'))
Radius = abs(SLM.XX(1,1)/tan((SLM.TetamaxX*pi/180)));
SLM.Zrange = SLM.FocalFS^2/Radius;
%disp(strcat('Along the Z axis : ',num2str(SLM.Zrange/Setup.Magnification.^2),' micrometers'))

end

