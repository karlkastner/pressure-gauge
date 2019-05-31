% Sat Nov 29 15:08:38 CET 2014
% Karl Kastner, Berlin
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
% TODO also return actual time slots
function T = check_filetime(obj)
	filetime = [cvec(obj.filetimeMin) cvec(obj.filetimeMax)];
	T = [];
	for idx=1:size(filetime,1)
	 for jdx=idx+1:size(filetime,1)
		% start time of first file falls into in time span of second file
		if (   (filetime(idx,1) >= filetime(jdx,1)) ...
                     && (filetime(idx,1) <= filetime(jdx,2)) )
			T(end+1,:) = [filetime(idx,1) idx jdx];
		end
		% start time of second file falls into time span of second file
		if (   (filetime(jdx,1) >= filetime(idx,1))  ...
                     && (filetime(jdx,1) <= filetime(idx,2) ) )
			T(end+1,:) = [filetime(jdx,1) jdx idx];
		end
%		if (~( filetime(idx,2) < filetime(jdx,1) ...
%		     | filetime(jdx,2) < filetime(idx,1) ) )
%			fprintf(1,'WARNING: time slots overlap\n%s\n%s\n',obj.filename{idx},obj.filename{jdx});
	 end % for jdx
	end % for idx
	obj.overlap = T;
	if (~isempty(T))
		fprintf(1,'WARNING: file periods of sensor %d overlap\n',obj.serial_number);
		%overlap\n%s\n%s\n',obj.filename{idx},obj.filename{jdx});
	end
end % check_filetime

