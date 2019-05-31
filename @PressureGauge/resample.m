% Do 11. Sep 13:15:27 CEST 2014
% Karl Kastner, Berlin
% 
% resample time series data
%
% This programme is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This programme is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this programme. If not, see <https://www.gnu.org/licenses/>.
function [objr obj] = resample(obj,itime)
	objr              = PressureGauge();
	objr.isresampled  = true;

	% copy essential scalar properties
	field_C = {'serial_number', 'type_str', ... 
		   'location.name','location.easting','location.northing', ...
		   'location.channelname','location.S'};
	for field=rvec(field_C)
		objr = setfield_deep(objr,field{1},getfield_deep(obj,field{1}));
	end

	% resample essential time series
	objr.time        =  itime;
	objr.P1          =  interp1_limited(obj.time,obj.P1,itime,obj.dt_max,obj.imethod);
	objr.P2          =  interp1_limited(obj.time,obj.P2,itime,obj.dt_max,obj.imethod);
	objr.P1_minus_P2 =  interp1_limited(obj.time,obj.P1_minus_P2,itime,obj.dt_max,obj.imethod);
	objr.depth       =  interp1_limited(obj.time,obj.depth,itime,obj.dt_max,obj.imethod);
end

