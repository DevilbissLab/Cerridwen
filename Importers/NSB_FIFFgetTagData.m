function [tag,fpos,status] = NSB_FIFFgetTagData(fid,tag)
%Gets data regardless of type
%
%

if isfield(tag,'pos')
    fseek(fid,tag.pos,'bof');
    tag = NSB_FIFFgetCurTag(fid);
end

status = true;
switch tag.type
    case 0 %void
        tag.data = [];
        fpos = ftell(fid);
    case 1 %byte
        tag.data = fread(fid,tag.size,'uint8=>uint8');
        fpos = ftell(fid);
    case 2 %int16
        tag.data = fread(fid,tag.size/2,'int16=>int16');
        fpos = ftell(fid);
    case 3 %int32
        tag.data = fread(fid,tag.size/4,'int32=>int32');
        fpos = ftell(fid);
    case 4 %float
        tag.data = fread(fid,tag.size/4,'single=>double');
        fpos = ftell(fid);
    case 5 %double
        tag.data = fread(fid,tag.size/8,'double'); 
        fpos = ftell(fid);
    case 6 %julian
        tag.data = fread(fid,tag.size/4,'int32=>int32');
        fpos = ftell(fid);
    case 7 %uint16
        tag.data = fread(fid,tag.size/2,'uint16=>uint16');
        fpos = ftell(fid);
    case 8 %uint32
        tag.data = fread(fid,tag.size/4,'uint32=>uint32');
        fpos = ftell(fid);
    case 9 %uint64
        tag.data = fread(fid,tag.size/8,'uint64=>uint64');
        fpos = ftell(fid);
    case 10 %char/ascii/string
        tag.data = fread(fid,tag.size,'uint8=>char')';
        fpos = ftell(fid);
    case 11 %int64
        tag.data = fread(fid,tag.size/8,'int64=>int64');
        fpos = ftell(fid);
    case 13 %dau_pac13
        tag.data = [];
        status = false;
    case 14 %dau_pac14
        tag.data = [];
        status = false;
    case 16 %dau_pac16
        tag.data = fread(fid,tag.size/2,'int16=>int16');
        fpos = ftell(fid);
    case 20 %complex_float
        tag.data = fread(fid,tag.size/4,'single=>double');
        tag.data = complex(tag.data(1:2:length(tag.data)),tag.data(2:2:length(tag.data)));
        fpos = ftell(fid);
    case 21 %complex_double
        tag.data = fread(fid,tag.size/8,'double');
    	tag.data = complex(tag.data(1:2:length(tag.data)),tag.data(2:2:length(tag.data)));
        fpos = ftell(fid);
    case 23 %old_pack
        tag.data = [];
        status = false;
    case 30 %ch_info_struct
        
        %Table A.3 
     tag.data.scanNo    = fread(fid,1,'int32=>int32');
	 tag.data.Channel     = fread(fid,1,'int32=>int32');
	 tag.data.ChannelType      = fread(fid,1,'int32=>int32');
	 tag.data.range     = fread(fid,1,'single=>double');
	 tag.data.cal       = fread(fid,1,'single=>double');
	 tag.data.coil_type = fread(fid,1,'int32=>int32');
	 %
	 %   Read the coil coordinate system definition
	 %
	 tag.data.loc        = fread(fid,12,'single=>double');
	 tag.data.coil_trans  = [];
	 tag.data.eeg_loc     = [];
	 tag.data.coord_frame = false;
	 %
	 %   Convert loc into a more useful format
	 %
	 loc = tag.data.loc;
	 if tag.data.ChannelType == 1 || tag.data.ChannelType == 301
	    tag.data.coil_trans  = [ [ loc(4:6) loc(7:9) loc(10:12) loc(1:3) ] ; [ 0 0 0 1 ] ];
	    tag.data.coord_frame = 1;
	 elseif tag.data.ChannelType == 2
	    if norm(loc(4:6)) > 0
	       tag.data.eeg_loc     = [ loc(1:3) loc(4:6) ];
	    else
	       tag.data.eeg_loc = [ loc(1:3) ];
	    end
	    tag.data.coord_frame = 4;
	 end
	 %
	 %   Unit and exponent
	 %
	 tag.data.unit     = fread(fid,1,'int32=>int32');
	 tag.data.unit_mul = fread(fid,1,'int32=>int32');
	 %
	 %   Handle the channel name
	 %
	 ch_name = fread(fid,16,'uint8=>char')';
	 %
	 % Omit nulls
	 %
	 len = 16;
	 for k = 1:16
	    if ch_name(k) == 0
	       len = k-1;
	       break
	    end
	 end
	 tag.data.ch_name = ch_name(1:len);
     fpos = ftell(fid);

    case 31 %id_struct
        tag.data.version = fread(fid,2,'int16');
        tag.data.machid = fread(fid,8,'uint8'); %< still not right
        tag.data.time_sec = fread(fid,1,'int32');
        tag.data.time_usec = fread(fid,1,'int32');
        fpos = ftell(fid);
    case 32 %dir_entry_struct
        tag.data = struct('kind',[],'type',[],'size',[],'pos',[]);
        for curDir = 1:tag.size/16-1
	    tag.data(curDir).kind = fread(fid,1,'int32');
	    tag.data(curDir).type = fread(fid,1,'int32');
	    tag.data(curDir).size = fread(fid,1,'int32');
	    tag.data(curDir).pos  = fread(fid,1,'int32');
        end
        fpos = ftell(fid);
    case 33 %dig_point_struct Table A.6
        tag.data.type    = fread(fid,1,'int32=>int32');
        tag.data.ID   = fread(fid,1,'int32=>int32');
        tag.data.location       = fread(fid,3,'single=>single');
        switch tag.data.type
            case 1
                tag.data.type = 'Cardinal';
                switch tag.data.ID
                    %there are ECG Cardinal Labels but unclear how to
                    %extarcat that info here
                    case 1
                        tag.data.ID = 'LPA';
                    case 2
                        tag.data.ID = 'Nasion';
                    case 3
                        tag.data.ID = 'RPA';
                    otherwise
                        tag.data.ID = '';
                end
            case 2
                tag.data.type = 'HPI';
            case 3
                tag.data.type = 'EEG-ECG';
            case 4
                tag.data.type = 'EEG-ECG';
            case 5
                tag.data.type = 'EEG-ECG';
            otherwise
                tag.data.type = 'NA';
        end
        fpos = ftell(fid);
    case 34 %ch_pos_struct
        tag.data = [];
        fpos = ftell(fid);
        status = false;
    case 35 %coord_trans_struct
        tag.data = [];
        fpos = ftell(fid);
        status = false;
    case 36 %dig_string_struct
        tag.data = [];
        fpos = ftell(fid);
        status = false;
    case 37 %stream_segment_struct
        tag.data = [];
        fpos = ftell(fid);
        status = false;
    otherwise
        tag.data = [];
        fpos = ftell(fid);
        status = false;
end
        