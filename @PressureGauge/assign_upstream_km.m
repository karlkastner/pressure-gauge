% 2014-11-27 11:52:53.641934477 +0100
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
% TODO, this should be better computed by a tree crawler from the sea leaves
% in the distance tree
function obj = assign_upstream_km(obj)

	C = load_upstream_km();
	serial_number = cell2mat(C(:,1));
	%for idx=1:length(K)
	fdx = find(obj.serial_number == serial_number);
	if (isempty(fdx))
		obj.location.S = NaN;
		obj.location.channelname = '';
	else
		obj.location.S = C{fdx,2};
		obj.location.channelname = C{fdx,3};
	end
end % assign_upstream_km

