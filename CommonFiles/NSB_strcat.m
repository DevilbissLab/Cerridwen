function t = NSB_strcat(varargin)
%NSB_STRCAT Concatenate strings.
%   Rewrite of STRCAT to have better and specific properties.
%
%   COMBINEDSTR = NSB_STRCAT(S1, S2, ..., SN) horizontally concatenates strings
%   in arrays S1, S2, ..., SN. Inputs can be combinations of single
%   strings, strings in scalar cells, character arrays with the same number
%   of rows, and same-sized cell arrays of strings. 
%
%   Notes:
%
%   Allows empty inputs. collapses multiple white space into a single
%   whitespace character. Trims lead and lag insignifigant characters.
%
%   Example:
%
%       strcat('Red',' ','Yellow',{'Green';'Blue'})
%
%   returns
%
%       'Red YellowGreenBlue'
%
%   See also CAT, CELLSTR.


narginchk(1, inf);

% initialise return arguments
t = '';

% return empty string when all inputs are empty
rows = cellfun('size',varargin,1);
if all(rows == 0)
    return;
end

%limit inputs to two dimensions
dims = (cellfun('ndims',varargin) == 2);
if ~all(dims)
    error(message('NSB:NSB_strfun:InputDimension'));
end


if all(rows == 1) && ~any(cellfun(@iscell,varargin))
    %if all varargin are one row and no cells.
    t = [varargin{:}];
else
    for n = 1:length(varargin)
        if ~iscell(varargin{n})
            t = [t, varargin{n}];
        elseif iscell(varargin{n})
            % Expand if cell is more than one row.
            str = '';
            for m = 1:rows(n)
                str = [str, varargin{n}{m}];
            end
             t = [t, str];
        else
           error(message('NSB:NSB_strfun:InputType'));
        end
    end
end

%Replace >1 white space with single space 
t = strtrim(regexprep(t,'\s{2,}',' '));
