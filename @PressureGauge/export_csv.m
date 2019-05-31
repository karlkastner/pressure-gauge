% Sun Jul 20 20:26:40 WIB 2014
% Karl Kastner, Berlin
%
% export data to csv
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
function obj = export_csv(obj,fid)
	fprintf(fid,'Date;Time;Depth\n');
	for idx=1:length(obj.time)
		fprintf(fid,'%s %f\n',datestr(obj.time(idx),'dd-mmm-yyyy;HH:MM:SS;'), obj.depth(idx));
	end
end % export_csv

