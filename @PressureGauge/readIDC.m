% Sun Mar  9 22:39:20 WIB 2014
% Karl Kastner, Berlin
%
% read IDC (Keller) data files, ported from Delft FEWS
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
function g = readIDC(iname)

    % Constants
	DF_ID_FILE            = 0;
	DF_ID_DEVICE          = 1;
	DF_ID_DATA            = 2;
	DF_ID_UNITS           = 3;
	DF_ID_PROFILE         = 4;
	DF_ID_CONFIG          = 5;
	DF_ID_WL_CONVERTED    = 6;
	DF_ID_AIR_COMPENSATED = 7;
	DF_ID_INFO            = 8;
        t0 = datenum('30/12/1899','dd/mm/yyyy');
	
	% variables
	g = struct();
	channel = [];
        userValArr = zeros(1,12,'single');

	fid = fopen(iname,'r');
	if (-1 == fid)
		error('Keller::readIDC:Unable to open file');
	end

	startTime = -1; 

        % Continue to read lines while
        % there are still some left to read
        while (1)
		nextByte = fread(fid,1,'uint8');
            	if (isempty(nextByte))
			break; % EOF
		end
		fseek(fid,-1,'cof');

            	% Read block ID
            	[blockId n] = readBlock(fid);
 
            switch (blockId)
		case { DF_ID_FILE }
                    % File Identification
                    g.version = readString(fid);
%		    Debug.print('version = %d\n',g.version);
                case { DF_ID_DEVICE }
 
                    % Device properties
		    % 0..3
                    lw = fread(fid,1,'int');
                    w1 = fix(lw / 65536);
                    w2 = mod(lw,65536);
 
                    g.class = fix(w1 / 256);
                    g.group  = mod(w1,256);
                    g.year   = fix(w2 / 256);
                    g.week   = mod(w2,256);
 
                    if (g.year == 3) 
                        if (g.week >= 10) 
                            abVersion0310 = true;
                        end
                    end
                    if (g.year > 3) 
                        abVersion0310 = true;
                    end
 
		    % 4..8
                    g.serialNumber = fread(fid,1,'int');
 
		    % 9
                    g.configuredAsWaterlevel = fread(fid,1,'uint8');

		    % 10 .. 
                    g.locationId = readString(fid);
		    % 11* ..
                    g.comment = readString(fid);
 
                    %if (isDebugEnabled()) 
                    %    disp('serial number = 'serialNumber);
                    %    disp('configured as waterlevel = 'configuredAsWaterlevel);
                    %    disp('comment = 'comment);
                    %    disp('location id = 'locationId);
                    %end
                case { DF_ID_DATA }
                    % Data records
                    z = fread(fid,1,'int');
%			% enlarge
%			for idx=1:length(channel)
%				channel(idx).time(channel(idx).n+z) = NaN;
%				channel(idx).longValue(channel(idx).n+z) = NaN;
%				channel(idx).singleValue(channel(idx).n+z) = NaN;
%			end

                    for idx=0:z-1
                        % The date is stored as the number of days since 30 Dec 1899. Quite why it is not 31 Dec is not clear. 01 Jan 1900 has a days value of 2.
			% 0..7
                        doubleTime = fread(fid,1,'double');
 
			time = doubleTime + t0;
 
                        % Bewaar lijst met tijden voor de reeks met inhangdiepte's
                        if (startTime == -1)
				g.startTime = time;
			end
 
			% 8
                        cdx = fread(fid,1,'uint8')+1;

			channel(cdx).n = channel(cdx).n + 1;
			channel(cdx).time(channel(cdx).n,1) = time;

			% skip 3 bytes
			%  9 .. 11 
			void = fread(fid,3,'uint8');
			% 12 .. 16 
                        channel(cdx).singleValue(channel(cdx).n,1) = fread(fid,1,'float');
			% 17..20
                        channel(cdx).longValue(channel(cdx).n,1) = fread(fid,1,'int');
                        % Skip 4 bytes
			% 21..24
			void = fread(fid,4,'uint8');
		    end % for idx                    
 
                case {DF_ID_UNITS}
 
                    [retval channel] = parseUnits(fid,channel);
%                    if (!retval){
%                        log.error('Bestand bevat niet de juiste eenheden');
%                        throw new Exception('Bestand bevat niet de juiste eenheden');
%                    end

			% preallocate
			for idx=1:length(channel)
				channel(idx).n = 0;
				channel(idx).time = zeros(1e6,1,'double');
				channel(idx).longValue = zeros(1e6,1,'int32');
				channel(idx).singleValue = zeros(1e6,1,'single');
			end
 
                case { DF_ID_PROFILE }
 
                    % Read device profile
                    for idx=0:length(userValArr)-1
                        userValArr(idx+1) = fread(fid,1,'float');
%                        if (isDebugEnabled()) disp('userValArr 'userValArr[i]);
                    end % for idx
 
                    g.installationDepth = userValArr(2+1);
                    %if (isDebugEnabled()) disp('installation depth 'installationDepth);
 
                    g.heightOfWellhead = userValArr(3+1);
%                    if (isDebugEnabled()) disp('Height of wellhead above sea level 'heightOfWellhead);
 
                    g.offset = userValArr(4+1);
                    %if (isDebugEnabled()) disp('Offset 'offset);
 
                    g.waterDensity = userValArr(5+1);
%                    if (isDebugEnabled()) disp('Water density 'waterDensity);
 
                    availableChannels = fread(fid,1,'int16');

			% quick fix
		    if (availableChannels > 0)
 
                    if (bitand(availableChannels,2) == 2) 
                        p1min = fread(fid,1,'float');
                        p1max = fread(fid,1,'float');
         %               if (isDebugEnabled()) disp('P1 min 'p1min);
        %                if (isDebugEnabled()) disp('P1 max 'p1max);
                    end
                    if (bitand(availableChannels,4) == 4) 
                        p2min = fread(fid,1,'float');
                        p2max = fread(fid,1,'float');
       %                 if (isDebugEnabled()) disp('P2 min 'p2min);
      %                  if (isDebugEnabled()) disp('P2 max 'p2max);
                    end
                    if (bitand(availableChannels,8) == 8) 
                        t1min = fread(fid,1,'float');
                        t1max = fread(fid,1,'float');
     %                   if (isDebugEnabled()) disp('T1 min 't1min);
    %                    if (isDebugEnabled()) disp('T1 max 't1max);
                    end
                    if (bitand(availableChannels,16) == 16) 
                        tob1min = fread(fid,1,'float');
                        tob1max = fread(fid,1,'float');
   %                     if (isDebugEnabled()) disp('TOB1 min 'tob1min);
  %                      if (isDebugEnabled()) disp('TOB1 max 'tob1max);
                    end
                    if (bitand(availableChannels,32) == 32) 
                        tob2min = fread(fid,1,'float');
                        tob2max = fread(fid,1,'float');
 %                       if (isDebugEnabled()) disp('TOB2 min 'tob2min);
%                        if (isDebugEnabled()) disp('TOB2 max 'tob2max);
                    end
		end
 
                case { DF_ID_CONFIG }
 
                    % Record configuration
                    g.startDate = fread(fid,1,'int32');
                    g.stopDate  = fread(fid,1,'int32');
                    lw          = fread(fid,1,'int32');
 
                    g.recordedChannels = fix(lw / 65536);
                    g.recordModus      = mod(lw,65536);
 
                    g.trigger1 = fread(fid,1,'float');
                    g.trigger2 = fread(fid,1,'float');
 
                    if (abVersion0310)
                        g.recFixCounter = fread(fid,1,'int32');
                        g.recModCounter = fread(fid,1,'int16');
                    else
                        lw = fread(fid,1,'int32');
                        g.recFixCounter = fix(lw / 65536);
                        g.recModCounter = mod(lw,65536);
                    end
 
                    sw = fread(fid,1,'int16');
 
                    g.recModChannel  = fix(sw / 256);
                    g.recSaveCounter = mod(sw,256);
 
                    g.recFastModCounter = fread(fid,1,'int16');
                    g.recEndless        = fread(fid,1,'int8');
 
                case { DF_ID_WL_CONVERTED }
 
                    % Waterlevel converted
                    g.convertedIntoWaterlevel = fread(fid,1,'int8');
 
                case {DF_ID_AIR_COMPENSATED}
 
                    % Airpressure compensation
                    g.airCompensated = fread(fid,1,'int8');
 
                case {DF_ID_INFO}
 
                    % Additional information
                    g.batteryCapacity = fread(fid,1,'int8');
                    for idx=0:10-1
                        g.reserve(idx+1) = fread(fid,1,'int32');
                    end
                    % Read CRC16 sum of the whole file
                    g.crc16 = fread(fid,1,'int16');
		otherwise
			error('idc2txt','unknown block id');
	end % switch
	end % while
	% truncate
	for idx=1:length(channel)
		channel(idx).time=channel(idx).time(1:channel(idx).n);
		channel(idx).longValue = channel(idx).longValue(1:channel(idx).n);
		channel(idx).singleValue = channel(idx).singleValue(1:channel(idx).n);
	end
	g.channel = channel;
    	fclose(fid);
end % function
 
function [block n] = readBlock(fid)
        block = fread(fid,1,'uint16');
        w1 = fread(fid,1,'uint16');
        w2 = fread(fid,1,'uint16');
 
        n = (65536 * w1) + w2;
end % readBlock
 
function [retval channel] = parseUnits(fid,channel)
%            String locationId,
%            DefaultTimeSeriesHeader header)
 
        retval = true;
        availableChannels = fread(fid,1,'int16');
        amountOfUnits = fread(fid,1,'int16');
 
        for idx=0:amountOfUnits-1
	    % channel index
	    % 0 
            cdx = fread(fid,1,'uint8')+1;
	    % 1..7
	    chr = fread(fid,7,'uint8');
            channel(cdx).unit = char(reshape(chr,1,[]));

%            if(unit.equalsIgnoreCase('m'))
%               retval = false;
%            end
 
%           header.setUnit(unit);
%            if (unit.contains('Â°C')) 
%                header.setUnit('deg C');
%            end
 
            % multiplier
	    % 8..11
            channel(cdx).multiplier = fread(fid,1,'float');

            % offet
	    % 12..15
            channel(cdx).offset = fread(fid,1,'float');
 
            % description
	    % 16..57
	    % something is strange here, count has to be reduced by -1 if char is used instead of uint8
            channel(cdx).description = char(reshape(fread(fid,41,'uint8'),1,[]));

	    % skip
	    % 58..60
	    channel(cdx).void = fread(fid,3,'int8');
%            if (isDebugEnabled()) 
%                disp('channel 'channel);
%                disp('multiplier 'multiplier);
%                disp('offset 'offset);
%                disp('unit 'unit);
%                disp('description 'description);
%            end
 
%            header.setLocationId(locationId);
%            header.setParameterId(Byte.toString(channel));
 
%            contentHandler.createTimeSeriesHeaderAlias(channel, header);
%        end
% 
%        return retval;
    end
end % function parseUnits

function retval = readString(fid)
	length = fread(fid,1,'uint16');
	retval ='';
        if (length > 0)
            retval = char(reshape(fread(fid, length, 'uint8'),1,[]));
            %retval = char(reshape(fread(fid, length, 'char'),1,[]));
	end
end % function readString()


