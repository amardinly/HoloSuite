function locations = SatsumaRigFile();
% Version 1.1
% Edited by Alan Mardinly 1/6/17
% IF YOU CHANGE THIS FILE, UPDATE THE VERSION AND ENSURE COPIES ARE PRESENT
% AND SYNCHED ON ALL RELEVANT COMPUTERS!  THIS FILE MUST BE IN THE PATH FOR
% ALL ELEMENTS OF HOLOSUITE

%% The Usual Path
locations.HoloRequest_DAQ='Z:\holography\SatsumaRig\HoloRequest-DAQ\';
locations.HoloRequest_DAQ_PrintedHolo='Z:\holography\SatsumaRig\HoloRequest-DAQ\PrintedHolo\';
locations.PowerCalib = 'Z:\holography\Calibration Parameters\20X_Objective_Calibration_LaserPower.mat';
locations.savePath='C:\data\';
locations.ROIanalysisDefaultPath = 'Z:\';
locations.customHolo = 'Z:\holography\SatsumaRig\CustomHolo\';
locations.HoloRequest='Z:\holography\SatsumaRig\HoloRequest\';

locations.TransferFolder='Z:\holography\TransferFolder\';
locations.CalibrationParams='Z:\holography\Calibration Parameters\';
locations.DisplayFolder='Z:\holography\Calibration Displays\';
locations.ScanImageFolder='Z:\holography\CalibrationScanimage\';
locations.SLMComputer='Z:\holography\Calibration Codes\CALIBRATION_CODE_SLM_Computer\';
locations.saveSequence='Z:\holography\SatsumaRig\Saved_Sequences\';


%% Path to IMaging if Inhbition is down
% locations.HoloRequest_DAQ='\\128.32.173.33\Imaging\STIM\HoloRequest-DAQ\';
% locations.HoloRequest_DAQ_PrintedHolo='\\128.32.173.33\Imaging\STIM\HoloRequest-DAQ\PrintedHolo\';
% locations.PowerCalib = '\\128.32.173.33\Imaging\STIM\Calibration Parameters\20X_Objective_Calibration_LaserPower.mat';
% locations.savePath='C:\data\';
% locations.ROIanalysisDefaultPath = '\\128.32.173.33\';
% % locations.customHolo = 'Z:\holography\SatsumaRig\CustomHolo\';
% locations.HoloRequest='\\128.32.173.33\Imaging\STIM\HoloRequest\';
% 
% locations.TransferFolder='\\128.32.173.33\Imaging\STIM\Calibration TransferFolder\';
% locations.CalibrationParams='\\128.32.173.33\Imaging\STIM\Calibration Parameters\';
% locations.DisplayFolder='\\128.32.173.33\Imaging\STIM\Calibration Displays\';
% locations.ScanImageFolder='\\128.32.173.33\Imaging\STIM\CalibrationScanimage\';
% locations.SLMComputer='Z:\holography\Calibration Codes\CALIBRATION_CODE_SLM_Computer\';
% locations.saveSequence='\\128.32.173.33\Imaging\STIM\Saved_Holo_Sequences\';