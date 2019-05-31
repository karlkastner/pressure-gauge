% Sun Nov  2 12:32:58 CET 2014
% Karl Kastner, Berlin
%
% iir filter of specified data field
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
% TODO, this implicitely assumes a constant time step
function [y, obj] = filter(obj,fieldname,T)
	x = getfield(obj,fieldname);
	if (length(x) > 2)
%		dt = obj.time(2)-obj.time(1);
		dt = nanmedian(diff(obj.time));
		n = round(T/dt);
		f = ones(n,1)/n;
		y = conv(x,f,'same');
		y(1:min(floor(n/2),end)) = NaN;
		y(max(1,end-ceil(n/2)-1):end) = NaN;
	else
		y = x;
	end
end % filter()

