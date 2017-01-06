function ScaleFactor=ScaleEnergy(ROIlocation,locations,TF)
   load([locations.CalibrationParams '20X_Objective_Zoom_2_XYZ_Calibration_Points.mat']);
   load(locations.PowerCalib,'LaserPower');
   [ Query_T ] = function_3DCofC(ROIlocation', XYZ_Points );

   if ~TF;
   load([locations.CalibrationParams 'xyPowerInterp.mat']);
   ScaleFactor=xyPowerInterp(Query_T(1),Query_T(2)); 

   else
   load([locations.CalibrationParams 'TFPowerMap.mat']);
   ScaleFactor=TFPowerMap(Query_T(1),Query_T(2)); 

   end
    



    
