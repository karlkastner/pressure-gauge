% Sat  9 Jul 12:55:49 CEST 2016
% Karl Kastner, Berlin
%
% decompose the water level data into tidal species by means of the wavelet transform
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
function [tide, obj] = water_level_wavelet_transform(obj,meta)
	
%	meta = water_level_metadata();

	tide = Tide_wft();
			
	% for each station
	for idx=1:length(obj)
	tide(idx) = Tide_wft(...
			'F_low',meta.wft.F_low, ...
			'n_low',meta.wft.n_low, ...
			'F', meta.wft.F, ...
			'n', meta.wft.n, ...
			'winstr', meta.wft.winstr, ...
			'dt_max', meta.wft.dt_max, ...
			'pmin', meta.wft.pmin ...
			);

		time = obj(idx).time;
		% TODO level for model ???
		val  = obj(idx).depth;

		t0 = time(1);
		dt = time(2)-time(1);
		tide(idx).transform(t0,dt,double(val));

		% copy features
		tide(idx).location.name = obj(idx).location.name;

		% distance from sea
		tide(idx).location.S  = obj(idx).location.S;
		tide(idx).location.easting  = obj(idx).location.easting;
		tide(idx).location.northing  = obj(idx).location.northing;
	end % for idx
	
end % wavelet_transform

