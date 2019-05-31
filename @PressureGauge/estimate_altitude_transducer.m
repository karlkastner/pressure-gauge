% Mon Dec  1 10:28:40 CET 2014
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
function [C, M, np, obj] = estimate_altitude_transducer(obj)
	
	% TODO no magic numbers
	np = 14;

	% mean water level for 1-day period
	c0 = obj.constituents.c(:,1);
	C = c0;

	% filter
	fdx = find(isfinite(c0));
	nf = length(fdx);

	if (nf < 1)
		obj.altitude_sensor_pseudo = NaN;
	else

	c0 = sort(c0(fdx));

	% minimum water level
	x0_min = c0(1);
	% fit the extreme value distribution
	param  = gevfit(c0);
	% minimum water level estimated by the gev
	x0_gev = param(3);

	% TODO this should be set up in slices from one valid section to the next
%	rho(idx,1) = c0(1:end-1)'*c0(2:end)/(c0(1:end-1)'*c0(1:end-1));
%	rho(idx,2:3) = [c0(2:end-1)-c0(1:end-2) c0(2:end-1)] \ c0(3:end);

	% linear extrapolation
	p = (1:np)'/nf;
	A  = [-ones(np,1) c0(1:np)];
	c  = A \ p;
	x0_lin = -roots([c(2) c(1)]);

%	A_ = [ones(np,1) p];
%	c = A_ \ c0(1:np);
%	res = A_*c - c0(1:np);
	%title([K(idx).placename ' ' num2str([z c(2)])]);

	% mode as a gamma function
	mu          = mean(c0);
	s           = std(c0);
	sk          = skewness(c0);
	x0_gamma    = mu - 2/sk*s;

	obj.altitude_sensor_pseudo_  = -[x0_min, x0_lin, x0_gamma, x0_gev];

	obj.altitude_sensor_pseudo = -x0_lin;

	end % if ~ isempty(nt)

end % correct level

