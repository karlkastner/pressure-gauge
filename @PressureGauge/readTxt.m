% Mon Mar 10 08:26:17 WIB 2014
% Karl Kastner, Berlin
%
% read Keller data from text file generated by ConvTXT
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
function g = readTxt(filename)
	% read in the entire file
	fid = fopen(filename,'r');
	if (-1 == fid)
		fprintf('error: failed to open file\n');
		error('failed to open file');
	end
	str = fread(fid,'*char');
	fclose(fid);
	C = textscan(str,'%s','delimiter','\r');
	C = C{1};

	% extract serial number
	%s = fgetl(fid);
	sn_str = regexprep(regexprep(C{1},'.*:\s*',''),'\s.*','');
	g.sn = str2num(sn_str);

	jdx = 1;
	header = {};
	% skip rows until row starting with "Channel"
	while (jdx <= length(C))
		% tokenise
		token = strsplit(C{jdx},'\s\s*');
		if (1 == strcmp('Channel', token{1}) )
			%header = { token{2:end} };
			for idx=1:length(token)-1;
				% as P2-P1 is not a valid field name
				g.header{idx} = strrep(token{idx+1},'-','_minus_');
			end
			break;
		end
		jdx = jdx+1;
	end 
%{
	% read lines until line starting with "Channel"
	while (1)
		% get line without terminating character
		s = fgetl(fid);
		% tokenise
		token = strsplit(s,'\s\s*');
		if (1 == strcmp('Channel', token{1}) )
			%header = { token{2:end} };
			for idx=1:length(token)-1;
				% as P2-P1 is not a valid field name
				header{idx} = strrep(token{idx+1},'-','_minus_');
			end
			break;
		end
	end 
	% jump the unit line
	s = fgets(fid);
%}
	% jump the unit row
	jdx=jdx+2;

	% process row wise until end of file
	idx=1;

	while (jdx <= length(C))
		% get line
	%	s = fgets(fid);
	%	if (-1 == s)
	%		break;
	%	end
		% tokenise
		token = strsplit(C{jdx},'\t');
		% time in format 29-09-2013 06:42:14
		g.time(idx,1) = datenum([token{1}], 'dd/mm/yyyy HH:MM:SS');
		%g.time(idx,1) = datenum([token{1} ' ' token{2}], 'dd-mm-yyyy HH:MM:SS');
%[header{:} ]
%[token{:}]
%size(header)
%size(token)
%token{:}
		for kdx=1:length(g.header)
			%field = getfield(obj,header{kdx});
			%field(idx,1) = str2num(token{kdx+1});
			g.field(idx,kdx) = str2num(token{kdx+1});
			%obj = setfield(obj,header{kdx},field);
		end
		idx = idx+1;
		jdx = jdx+1;
	end % while 1

%{
	% read line wise until end of file
	idx=1
	while (1)
		% get line
	%	s = fgets(fid);
	%	if (-1 == s)
			break;
		end
		% tokenise
		token = strsplit(s,'\s\s*');
		% time in format 29-9-2013  6:42:14
		g.time(idx,1) = datenum([token{1} ' ' token{2}], 'dd/mm/yyyy HH:MM:SS');
		%g.time(idx,1) = datenum([token{1} ' ' token{2}], 'dd-mm-yyyy HH:MM:SS');
		for jdx=1:length(header)
			field = getfield(obj,header{jdx});
			field(idx,1) = str2num(token{jdx+2});
			obj = setfield(obj,header{jdx},field);
		end
		idx = idx+1;
	end % while 1
%}

end % function readTxt

