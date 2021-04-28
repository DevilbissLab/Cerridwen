function [status,msg] = NSB_WriteGenericCSV(input, filename, append)
%
%
% This has to be a low level write since it is mixed strings and data
%updated DMD July 10, 2013 to handle single row inputs

status = false;
msg = [];
curRow = 0;

try
    if nargin < 3
        fid = fopen(filename, 'w+');
        append = false;
    else
        if append == true
            fid = fopen(filename, 'a');
            fprintf(fid, '\n');
        else
            fid = fopen(filename, 'w+');
        end
    end
    if fid == -1
        msg = [filename,' cannot be opened.'];
        return;
    end
    
    inClass = class(input);
    
    switch inClass
        case 'char'
            if size(input,1) == 1 %char array
                    fprintf(fid, '%s', input);
            else %vertcat string array
                str = '';
                for curRow = 1:size(input,1)
                    str = [str, deblank(input(curRow,:)), ','];
                end
                str = str(1:end-1); %trim last comma of line
                    fprintf(fid, '%s', str);
            end
        case {'double','single'}
            str = '';
            [r,c] = size(input);
            for curCol = 1:c
                str = [str '%6.10e,'];%str = [str '%12.9f,'];
            end
            str = str(1:end-1); %trim last comma of line
            if r>1
            for curRow = 1:r-1
                fprintf(fid, [str '\n'], input(curRow,:));
            end
            end
            fprintf(fid, str, input(curRow+1,:));
            
        case 'cell'
            %mixed input
            [r,c] = size(input);
            for curRow = 1:r
                str = '';
                for curCol = 1:c
                    if ischar(input{curRow,curCol})
                        str = [str, '%s,'];
                    elseif isnumeric(input{curRow,curCol})
                        str = [str, '%6.10e,'];%str = [str, '%12.8f,'];
                    end
                end
                str = str(1:end-1); %trim last comma of line
                if curRow ~= r
                    fprintf(fid, [str '\n'], input{curRow,:});
                else
                    fprintf(fid, str, input{curRow,:});
                end
            end
        otherwise
            msg = 'Datatype not supported.';
            fclose(fid);
            return;
    end
catch ME
    msg = ME.message;
    fclose(fid);
    return;
end
fclose(fid);
status = true;
