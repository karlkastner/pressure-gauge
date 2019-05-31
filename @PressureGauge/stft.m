% Mon Dec  1 14:22:20 CET 2014
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
function [stft, obj] = stft(obj,meta)

	% Ti = (1 + 1/24*50.4/60);
	% interval (here 1 day, not lunar day (letter did not give better fits)
	Ti = meta.stft.Ti;
	% diurnal, semidiurnal, terdiurnal, quarterdiurnal, ...
	T  = Ti./(1:meta.stft.nf);

	for idx=1:length(obj)
		stft(idx)   = STFT('t0',obj(idx).time(1),'tend',obj(idx).time(end),'T',T,'Ti',Ti);
		stft(idx).transform(obj(idx).time,obj(idx).depth);
	end

end % harmonic_analysis

