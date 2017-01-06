function ScaleFactor=correctPower(ROIlocation,I)
  global ExpStruct 
    
   useNpoints =5;

    roi= ExpStruct.Holo.ROIdata.rois(ExpStruct.Holo.currentROIsON);
    Query=[ roi.centroid(1),roi.centroid(2),roi.Zlevel];  %CHECK TO MAKE SURE ZLEVEL WORKS WELL
    
    %find nearest point sampled
    d=bsxfun(@minus,I(1:3,:)',Query);
    d=d.*d;
    d=sum(d');
    d=sqrt(d);
    
   [ dSort dIndx ]= sort(d,'ascend');
    
    weightedAvg=1./(dSort(1:useNpoints)./mean(dSort(1:useNpoints)));
    ScaleFactor=mean( I(4,dIndx(1:useNpoints)).*weightedAvg);   

    
    %wattRequest=wattRequest*ScaleFactor;
    