% Mo 25. Jan 13:39:40 CET 2016
% Karl Kastner, Berlin
%
% apply sensor specific corrections
% b) change absolut water level for sensors that were moved up or down
% used redeployment information should maybe be saved in the Keller structure
%
% two types: serial_number replacement and offset correction / splitting
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
%
function obj = apply_corrections(obj,cor,coordinates)
	% TODO no magic numbers
	dt_max = 0.25;

	% calculate missing derived quantities
	if (isempty(obj.P1_minus_P2))
		obj.P1_minus_P2 = obj.P1 - obj.P2;
	end
	fdx = isnan(obj.P1_minus_P2);
	obj.P1_minus_P2(fdx) = obj.P1(fdx) - obj.P2(fdx);
	if (isempty(obj.depth))
		obj.depth = Constant.pressure_to_depth(obj.P1_minus_P2,0);
	end
	fdx = isnan(obj.depth);
	obj.depth(fdx) = Constant.pressure_to_depth(obj.P1_minus_P2(fdx),0);

	% back up uncorrected data
	% TODO, copy before
%	field = {'time','P1','P2','P1_minus_P2','depth'};
%	for idx=1:length(field)
%		obj.orig.(field{idx}) = obj.(field{idx});
%	end

	% a) change serial number of replaced of sensors (alias)
	%    filesn remains
	for idx=1:size(cor.replace,1)
		serial_number   = cor.replace(idx,1:2);
		time = cor.replace(idx,3:4);
		% TODO, so far only the start time is checked
		if ( (serial_number(1) == obj.filesn) ...
		     && (obj.time(1) > time(1)) ...
		     && (obj.time(1) < time(2)) )
			fprintf('Susbtituting serial number %d with %d for file %s\n',serial_number(1),serial_number(2),obj.filename{1});
			obj.serial_number = serial_number(2);
			obj.rdate(end+1,:) = time;
		end
	end

	% b) clock correction, where time was set incorrectly during read out
	% Note: this has to precede following other corrections
	% Note: one clock fix is already included in the HADCP read out
	for idx=1:size(cor.time_offset_time,1)
		serial_number       = cor.time_offset_time(idx,1);
		if (obj.serial_number == serial_number)
			t_min       = cor.time_offset_time(idx,2);
			% TODO quick fix, make filetimeMin a function
			% or better an index
			if (isempty(obj.filetimeMin))
				obj.filetimeMin = obj.time(1);
			end
			dt      = obj.filetimeMin-t_min;
			[dt fn] = min(abs(dt));
			if (dt < dt_max)
			fprintf('Applying time shift to sn %d at %s\n',serial_number,datestr(t_min));
			%[mv fn]   = min(abs(obj.filetimeMin-t_min));
			%if (mv ~= 0)
			%	warning('no exact match');
			%end
				t_offset = cor.time_offset_time(idx,3);
				fdx	 = find(obj.FileNumber == fn);
				obj.time(fdx)        = obj.time(fdx) - t_offset;
			else
				fprintf('Not applying time shift to serial_number %d at %f, no near file start\n',serial_number,t_min);
			end
		end
	end % for idx

	% c) invalidate time slots where the sensor was not submerged / malfunctioning
	%    for simplicity this is referenced by serial_number (station) not by fsn (file)
	for idx=1:size(cor.invalidate,1)
		serial_number   = cor.invalidate(idx,1);
		time = cor.invalidate(idx,2:3);
		if (serial_number == obj.serial_number)
			% this can apply to a selected number of samples
			% within and beyond one file
			fdx = ( obj.time > time(1) ) ...
                                    & ( obj.time < time(2) );
			obj.P1(fdx)          = NaN;
			% fix of fix, do not spoil air pressure refference in Sanggau, even if water pressure is corrupted
			if (obj.serial_number ~= 15796)
				obj.P2(fdx)          = NaN;
			end
			obj.P1_minus_P2(fdx) = NaN;
			obj.depth(fdx)       = NaN;
			obj.idate(end+1,:)   = time;
		end
	end

%	% invalidate samples
%	for idx=1:size(cor.invalidate_ID,1)
%		serial_number   = cor.invalidate_ID(idx,1);
%	        fn   = invalidate_ID(idx,2);
%		if(serial_number == obj.serial_number)
%			% this can apply to a selected number of samples
%			% within and beyond one file
%			fdx = (obj.FileNumber == fn);
%%			obj.time(fdx)  = NaN;
%			obj.P1(fdx)    = NaN;
%			obj.P2(fdx)    = NaN;
%			obj.depth(fdx) = NaN;
%		end
%	end

	% c) correct depth offsets for sensors that were moved vertically
	%    for simplicity this is referenced by serial_number (station) not by fsn (file)
	for idx=1:size(cor.P1_offset,1)
		serial_number       = cor.P1_offset(idx,1);
		if (serial_number == obj.serial_number)
			delta_P1 = cor.P1_offset(idx,2);
			time     = cor.P1_offset(idx,3:4);
			% this can apply to a selected number of samples
			% within and beyond one file,
			% e.g. between one relocation and the next
			fdx = (obj.time > time(1)) ...
                                    & (obj.time < time(2));
			obj.P1(fdx) = obj.P1(fdx) + delta_P1;
			obj.P1_minus_P2(fdx) = obj.P1_minus_P2(fdx) + delta_P1;
			obj.odate(end+1,:) = time;
		end
	end


	% TODO this should also be relocation data file and not hard coded
	if (obj.serial_number == 10700)
		t0 = datenum('24-11-2013 12:31:01','dd-mm-yyyy HH:MM:SS');
		ts = (5 + 59/60 + 40/3600)/24;				
		fdx = find(obj.time < t0);
		obj.time(fdx) = obj.time(fdx)+ts;
	end

	% relocation of sensor
%	P0 = datenum('24/07/2014','dd/mm/yyyy');
%	if (5315 == obj.serial_number & obj.time(1) >= P0)
%		obj.serial_number = 5315b;
%	end

%	% relocation of sensor
%	P0 = datenum('26/07/2014','dd/mm/yyyy');
%	if (5528 == obj.serial_number & obj.time(1) >= P0)
%		obj.serial_number = '5528';
%	end

	%
	% calculate derived quantities (depth,etc.)
	%

	% dead sample detection
	% the sensor is analogue and stores values as float
	% two subsequent values are almost never the same
	obj.sameflag1 = [false; (0==diff(obj.P1))];
	obj.P1(obj.sameflag1) = NaN;
%	obj.sameflag2 = [false; (0==diff(obj.P2))];
%	obj.P2(obj.sameflag2) = NaN;

	% find samples with submerged water level sensor
	% this correction is basic
	% actually also samples after the flooding are affected
	% flooding can also be detected by sudden gradient
	% and correlation with the water level (equal distance)
	obj.floodflag = obj.P2 > obj.P2_max;
	% there is now a fix by inferring local pressure from other sensors
%	fdx = find(obj.floodflag);
%	obj.P2(fdx) = obj.P2_max;
%	obj.P1_minus_P2(fdx) = obj.P1(fdx) - obj.P2(fdx);

	% check for samples where water pressure sensor fell dry
	% TODO, check that p1 close to p2
%	obj.dryflag = obj.orig.P1 < obj.P1_min;
%	obj.P1(obj.dryflag) = NaN;
%	obj.P1_minus_P2(obj.dryflag) = NaN;

	% recalculate pressure difference
	fdx = isnan(obj.P1_minus_P2);
	obj.P1_minus_P2(fdx) = obj.P1(fdx) - obj.P2(fdx);

	% recalculate depth
	switch(obj.type_str)
	case {'KELLER','HADCP'}
		obj.depth = Constant.pressure_to_depth(obj.P1_minus_P2,0);
	case {'TIDETABLE','CTD'}
		% nothing to do
	otherwise
		error('keller');
	end
	
% 
% apply sensor specific auxilary data
% Has to come after depth computation
%
	try
		fdx = find([coordinates.Keller_ser] == obj.serial_number);
		if (~isempty(fdx))
			obj.location.easting  = coordinates(fdx).X;
			obj.location.northing = coordinates(fdx).Y;
			obj.altitude_gps = coordinates(fdx).Altitude;
			obj.d_water_gps  = coordinates(fdx).trimble_wa;
			obj.altitude_water_surface_0 = obj.altitude_gps - obj.d_water_gps;
			% time of installation
 			t_str = num2str(coordinates(fdx).Time,'%04d');
 			%t_str = coordinates(fdx).Time1(end-3:end)];
			obj.time0_str    = [coordinates(fdx).calib_date t_str];
			%obj.time0_str    = [coordinates(fdx).day_of_ins t_str];
			if (isfinite(obj.altitude_water_surface_0) & (obj.altitude_water_surface_0 ~= 0))
				obj.time0             = datenum(obj.time0_str,'yyyy/mm/ddHHMM');
				% sensor depth of installation
				if (length(obj.time) > 1)
					% must have at least two samples for interpolation
					obj.depth0 = interp1(obj.time, obj.depth, obj.time0,'nearest','extrap');
				else
					obj.depth0 = obj.depth(1);
				end
			else
				obj.time0  = NaN;
				obj.depth0 = NaN;
			end
			obj.dt0 = min(abs(obj.time - obj.time0));
			% sensor level
			obj.altitude_sensor = obj.altitude_water_surface_0 - obj.depth0;
			%obj.altitude = coordinates(fdx).Altitude;
			%obj.pipe_above = coordinates(fdx).pipe_above;
			% obj.t0 = coordinates(fdx,6);
			%obj.t0 = NaN;
			obj.location.name = coordinates(fdx).placename;
		end % if (keep default values at NaN)
	catch e
		disp(e);
	end % load coordinates

	% file time (fixed)
	if (isempty(obj.filetimeMin))
		obj.filetimeMax = max(obj.time);
		obj.filetimeMin = min(obj.time);
	end
end % apply_corrections

