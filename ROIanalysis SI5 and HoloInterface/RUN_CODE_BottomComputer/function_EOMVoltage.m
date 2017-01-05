function [ Voltage ] = function_EOMVoltage(Voltage,Power,PowerRequest)


if PowerRequest<0
    disp('Negative power requested, will return 0')
    Voltage = 0
else
if PowerRequest<max(Power)
    
Voltage = interp1(Power,Voltage,PowerRequest);
else
    Voltage = interp1(Power,Voltage,max(Power));
    disp(strcat('Unable to put requested power, doing the best I can, power will be : ', num2str(max(Power)),' Watts'))
end
end

end

