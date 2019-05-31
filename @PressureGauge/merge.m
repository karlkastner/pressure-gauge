% Sun Nov  2 12:32:20 CET 2014
% Karl Kastner, Berlin
%
% concatenate data of two objects, i.e. data of multi read out files
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
function obj1 = merge(obj1, obj2)
	% check that time spans do not overlap
	% make this a separate function
	fn1 = length(obj1.filename);
	fn2 = length(obj2.filename);

	% increase FileNumber counter
	obj2.FileNumber = obj2.FileNumber + max(obj1.FileNumber);

	% verify consistency of file numbers
	if (obj1.serial_number ~= obj2.serial_number)
		disp('Warning: serial numbers do not match');
	end % if

	%
	% concatenate scalar values
	%
	for idx={'filename', 'filesn', 'filetimeMax', 'filetimeMin', ...
                 'batteryCapacity', ...
                 ... 'comment', 
                 ... 'locationId',
                 'startDate','startTime'}
		if (isempty(obj1.(idx{1})))
			obj1.(idx{1})(1:fn1) = NaN;
		end
		if (isempty(obj2.(idx{1})))
			obj2.(idx{1})(1:fn2) = NaN;
		end
		obj1.(idx{1})(fn1+1:fn1+fn2) = obj2.(idx{1});
	end

	%
	% concatenate installation time stamps
	%
	obj1.idate = [obj1.idate; obj2.idate];
	obj1.odate = [obj1.odate; obj2.odate];
	obj1.rdate = [obj1.rdate; obj2.rdate];
	obj1.idate = unique(obj1.idate,'rows');
	obj1.odate = unique(obj1.odate,'rows');
	obj2.rdate = unique(obj1.rdate,'rows');

	%
	% concatenate vector values
	%
	for idx={'time', 'P1', 'P2', 'P1_minus_P2', 'TOB1', ...
                 'TOB2', 'depth', 'FileNumber', ...
		 ... %'orig.time', 'orig.P1', 'orig.P2', 'orig.P1_minus_P2', 'orig.depth'
		 }, % Level
		data1 = getfield_deep(obj1,idx{1});
		data2 = getfield_deep(obj2,idx{1});
		if (isempty(data1))
			data1 = NaN(size(obj1.time));
		end
		if (isempty(data2))
			data2 = NaN(size(obj2.time));
		end
		obj1 = setfield_deep(obj1,idx{1},[cvec(data1); cvec(data2)]);
	end % for idx

	%
	% sort samples by time and remove duplicate samples
	% files may have duplicate samples if the start marker was not reset during read out
	%
	[obj1.time sdx] = unique(obj1.time);
	for idx={'P1', 'P2', 'P1_minus_P2', 'TOB1', ...
                 'TOB2', 'depth', 'FileNumber', ...
                 ... % 'orig.time', 'orig.P1', 'orig.P2', 'orig.P1_minus_P2', 'orig.depth'
		}, % level
		data = getfield_deep(obj1,idx{1});
		if (~isempty(data))
			obj1 = setfield_deep(obj1, idx{1}, data(sdx));
		end
	end % for idx

	% TODO, this should be done once at the end end not on every merge
	% convert depth to water level
	% TODO check paranthesis execution order for II and &&
	if (    ~isfinite(obj1.altitude_sensor) ...
             || (isfinite(obj2.altitude_sensor) ...
             && (abs(obj2.dt0) < abs(obj1.dt0))))
		obj1.altitude_sensor = obj2.altitude_sensor;
		obj1.altitude_water_surface_0 = obj2.altitude_water_surface_0;
		obj1.dt0             = obj2.dt0;
		% these value should actually be ident
		obj1.altitude_gps    = obj2.altitude_gps;
		obj1.d_water_gps     = obj2.d_water_gps;
		obj1.time0           = obj2.time0;
		obj1.time0_str       = obj2.time0_str;
	end
	
	% test
%	if (length(obj1.P1) ~= length(obj1.time))
%		error('length does not match');
%	end

	% level is dynamically generated
%	obj1.level = obj1.depth + obj1.altitude_sensor;
end % merge

