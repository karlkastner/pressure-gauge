% Thu Nov 21 10:58:07 UTC 2013
% Karl Kästner, Berlin
%
% class to read in data of Keller pressure gauges,
% can also read pressure from ADCPtools objects 
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
% TODO depth should be computed on demand from P1_minus_P2
% TODO data of the initial object is not concatenated
% TODO slot should be an object of its own
% TODO replacement information should be loaded from files
% TODO make replacement a flag
classdef PressureGauge < handle
	properties (Constant)
		% limits
		% was 1.015, but sanggau has marginal installation depth
		P2_max         = 1.013;
		P1_min         = 1.013;
	end % properties (Constant)
	properties
		%
		% scalar values (1 value per gauging station)
		%

		% serial number
		% this number is rather a unique ID for the station, as the sensor may be changed
		% actual serial_number of the sensor is given in filesn
		serial_number  = NaN;
		% atitude of GPS antenna
		% TODO, this does not need to be stored here
		altitude_gps   = NaN;
		% distance of GPS antenna to water level surface
		d_water_gps    = NaN;
		% altitude of water level surface
		altitude_water_surface_0 = NaN;
		% time of installation (actually time of vertical referencing)
		time0          = NaN;
		time0_str      = [];
		% time between referencing and closest water level sample
		dt0;
		% sensor depth at installation
		depth0         = NaN;
		% sensor level at installation
		altitude_sensor = NaN;
		altitude_sensor_pseudo_ = [];
		altitude_sensor_pseudo = NaN;
		altitude_sensor_extrapolated = NaN;
		% location of the sensor
		location = struct('name',      [] ...
                                  ,'easting',  NaN ...
                                  ,'northing', NaN ...
                                  ,'S',        NaN ...    % along channel distance
				  ,'channelname', [] ... % name of water body
                                  );
		% name of the location the sensor was installed
		% placename;
		% nx1 UTM Easting
		%X;
		% nx1 UTM Northing
		%Y;
		% upstream km
		% Su;
		% channelname
		% channelname = [];

		% sensor / generic data source type
		type_str;

		% flag indication, that the time series data was resampled
		isresampled;

		dt_max  = 3/24;
		imethod = 'pchip';

		%
		% values for each file (1 value per file)
		%

		% battery capacity on read out in per cent
		batteryCapacity = [];
		% comment stored in sensor
		comment;
		% location name stored in sensor
		locationId;
		% read out date
		startDate;
		% read out time
		startTime;

		% name of the source file
		filename = cell(0);
		% relocation dates
		rdate;
		% installation dates
		idate;
		%
		odate;
		% nf x 1 end time of file
		filetimeMax = [];
		% nf x 1 start time of file
		filetimeMin = [];
		% nf x 1 serial number of sensor per file
		filesn;

		%
		% time series data
		%

		% nx1 sample time
		time;
		% nx1 pressure 1 (water)
		P1;
		% nx1 pressure 2 (air)
		P2;
		% nx1 pressure difference
		P1_minus_P2;
		% nx1 temperatur 1
		TOB1;
		% nx2 temperature 2
		TOB2;
		% nx1 sensor depth g*(P2-P1)
		depth;
		% nx1 air pressure sensor was flooded (recoverable error)
		floodflag;
		% nx1 water pressure sensor fell dry (not recoverable error)
		dryflag;
		% nx1
		sameflag1;
		% nx1
		sameflag2
		% nx1 number of the source file the sample comes from
		FileNumber;
		% uncorrected data (relocation)
		overlap;

		% raw data (only available if DEBUG set)
		dat

		DEBUG = false;

	end % properties
	methods (Static)
		% read from raw data file
		dat = readIDC(iname);
		% read from text file
		dat = readTxt(filename);
	end % methods (Static)
	methods
	% constructor
	function obj = PressureGauge(filename)
		if (nargin() < 1)
			return;
		end

	%
	% read in sensor data
	%
		if (strcmpi(filename(end-3:end),'.mat'))
		% read from mat file (salinity, hadcp or tidetable)
			dat = load(filename);
		if (isfield(dat,'hadcp'))
			hadcp    = dat.hadcp;
			if (obj.DEBUG)
				obj.dat  = hadcp;
			end
			obj.serial_number   = double(hadcp.serial(1,:))*[1 256 65536 16777216]';
			obj.time = datenum(hadcp.timeV);
			fdx      = (hadcp.pressure > 1e9);
			obj.P1_minus_P2 = 1e-4 * double(hadcp.pressure(:));
			obj.P1_minus_P2(fdx) = NaN;
			% pseudo for standard pressure
			obj.P1   = obj.P1_minus_P2 + 1; %NaN(size(obj.P1_minus_P2));
			obj.P2   = NaN(size(obj.P1_minus_P2));
			obj.TOB1 = NaN(size(obj.P1_minus_P2));
			obj.TOB2 = NaN(size(obj.P1_minus_P2));
			obj.FileNumber = single(hadcp.FileNumber);
			obj.filename(1:max(obj.FileNumber)) = {filename};
			nf = max(obj.FileNumber);
			obj.filetimeMin = NaN(1,nf);
			obj.filetimeMax = NaN(1,nf);
			for idx=1:nf
				fdx = find(obj.FileNumber == idx);
				if (~isempty(fdx))
					obj.filetimeMin(idx) = obj.time(fdx(1));
					obj.filetimeMax(idx) = obj.time(fdx(end));
				end
			end
			% hadcp file is already concatenated, so sorting may be necessary
			% [obj.time, sdx] = unique(obj.time);
			%for idx={'P1', 'P2','P1_minus_P2', 'TOB1', 'TOB2', 'depth', 'FileNumber'} %, 'level'}
			%	if (~isempty(obj.(idx{1})))
			%		obj.(idx{1}) = obj.(idx{1})(sdx);
			%	end
			%end % for idx
			obj.type_str = 'HADCP';
		% this a salinity sensor
		elseif (isfield(dat,'s'))
			dat                  = dat.s;
			if (obj.DEBUG)
				obj.dat  = dat;
			end
			obj.serial_number               = dat.sn;
			obj.time             = dat.time;
			obj.FileNumber       = ones(size(dat.time),'single');
			obj.depth            = dat.DEPTH;
			obj.P2               = NaN(size(obj.depth));
			% pseudo pressure difference for fresh water density and standard temperature
			obj.P1_minus_P2      = Constant.depth_to_pressure(obj.depth,0);
			obj.P1               = obj.P1_minus_P2 + 1; %NaN(size(obj.P1_minus_P2));
			%obj.altitude_sensor  = -mean(obj.depth);
			obj.time0            = dat.time(1);
			obj.type_str             = 'CTD';
			%obj.location.X                = dat.X;
			%obj.location.Y                = dat.Y;
%			obj.location.name        = dat.placename;
		elseif (isfield(dat,'tidetable')) % this a tide prediction
			dat                  = dat.tidetable;
			if (obj.DEBUG)
				obj.dat  = dat;
			end
			obj.serial_number               = NaN;
			obj.time             = dat.time;
			obj.FileNumber       = ones(size(dat.time),'single');
			obj.depth            = dat.level;
			obj.P1               = NaN(size(obj.depth));
			obj.P2               = NaN(size(obj.depth));
			obj.P1_minus_P2      = NaN(size(obj.depth));
			obj.altitude_sensor  = -mean(obj.depth);
			obj.time0            = dat.time(1);
			obj.type_str         = 'TIDETABLE';
			obj.location.X       = dat.x;
			obj.location.Y       = dat.y;
			obj.location.name    = dat.placename;
		else
			error('here')
		end
		elseif (strcmpi(filename(end-3:end),'.txt'))
		% read from text file
			dat      = PressureGauge.readTxt(filename);
			obj.serial_number   = dat.sn;
			obj.time = dat.time;
			obj.FileNumber = ones(size(obj.time),'single');
			obj.filename{1} = filename;
			for kdx=1:length(dat.header)
				header = getfield(obj,dat.header{kdx});
				obj    = setfield(obj,header{kdx}, ...
				 		      dat.field(:,kdx));
			end % for
			if (obj.DEBUG)
				obj.dat     = dat;
			end
			obj.fileTimeMin     = obj.time(1);
			obj.fileTimeMax     = obj.time(end);
			obj.type_str        = 'KELLER';
		elseif (strcmpi(filename(end-3:end),'.idc'))
			% read from IDC file
			dat                 = PressureGauge.readIDC(filename);
			% take over scalar values
			obj.filename{1}     = filename;
			obj.batteryCapacity = dat.batteryCapacity;
			obj.comment{1}      = dat.comment;
			obj.locationId{1}   = dat.locationId;
			obj.serial_number              = dat.serialNumber;
			obj.startDate       = dat.startDate;
			obj.startTime       = dat.startTime;

			% take over vector values
			% channels are assumed to be in the order
			%  1  2     3    4  5  6
			% P1 P2 P1-P2 void T1 T2
			% channel 4 is unused/unknown
			obj.time            = dat.channel(2).time;
			obj.FileNumber      = ones(size(obj.time),'single');
			obj.P1_minus_P2 = dat.channel(1).singleValue;
			obj.P1          = dat.channel(2).singleValue;
			obj.P2          = dat.channel(3).singleValue;
			obj.TOB1        = dat.channel(5).singleValue;
			obj.TOB2        = dat.channel(6).singleValue;
			if (Debug.enabled)
				obj.dat         = dat;
			end
			n = length(obj.time);
			for idx={'P1', 'P2','P1_minus_P2', 'TOB1', 'TOB2', 'depth'} %, 'level'}
				obj.(idx{1})(end+1:n) = NaN;
			end % for
			obj.type_str = 'KELLER';
		else
			error('PressureGauge::unknown input file type');
		end % file type selection

	% convert string to numerical serial_number
	if (ischar(obj.serial_number))
		obj.serial_number = str2double(obj.serial_number);
	end

	% file serial number
	% Note: scalar serial_number may change when sensor is replaced, filesn array not
	obj.filesn = obj.serial_number;

	end % constructor

	% dynamic variables (to save space)
	% wgs84 surface altitude
	function level = level(obj)
		level = obj.altitude_sensor + obj.depth;
	end

	% pseudo surface altitude
	function plevel = plevel(obj)
		plevel = obj.altitude_sensor_pseudo + obj.depth;
	end

	% extrapolated and normalised surface altitude
	function elevel = elevel(obj)
		plevel = obj.altitude_sensor_extrapolated + obj.depth;
	end

	end % methods
end % classdef PressureGauge

