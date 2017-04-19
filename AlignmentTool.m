function varargout = AlignmentTool(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AlignmentTool_OpeningFcn, ...
                   'gui_OutputFcn',  @AlignmentTool_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

function AlignmentTool_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;
clc; zoom on;

%Set cursor properties
dcm = datacursormode(hObject);
set(dcm,'DisplayStyle','datatip','Enable','off','UpdateFcn',@onDCM);
set(0,'showhiddenhandles','on');
handles.hObject = hObject;

%link axes
linkaxes([handles.sourceAxes handles.targetAxes handles.outputAxes],'x');

%initialize handles properties
handles.dcm         = dcm;
handles.dataText    = [];
handles.shift       = [];
handles.output      = [];
handles.source.filename    = [];
handles.source.pathname    = [];
handles.source.data        = [];
handles.source.time        = [];
handles.source.xlimits     = [];
handles.source.ylimits     = [];
handles.source.index       = [];
handles.source.mark        = [];

handles.target.filename    = [];
handles.target.pathname    = [];
handles.target.data        = [];
handles.target.time        = [];
handles.target.xlimits     = [];
handles.target.ylimits     = [];
handles.target.index       = [];
handles.target.mark        = [];

% Update handles structure
guidata(hObject, handles);
end

function varargout = AlignmentTool_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;
end

function panelModes_SelectionChangedFcn(~, eventdata, handles)
currentlySelected = eventdata.NewValue;
switch currentlySelected
    case handles.radiobuttonZoomIn
        pan off;
        set(handles.dcm,'Enable','off');
        zoom on;
    case handles.radiobuttonZoomOut
        pan off;
        set(handles.dcm,'Enable','off');
        zoom out;
        zoom off
    case handles.radiobuttonPan
        set(handles.dcm,'Enable','off');
        zoom off;
        pan on;
    case handles.radiobuttonSelect
        zoom off;
        pan off;
        set(handles.dcm,'DisplayStyle','datatip','Enable','on','UpdateFcn',@onDCM);
    otherwise
        zoom off;
        pan off;
        set(handles.dcm,'Enable','off');
end
end

function output_txt = onDCM(~,eventObj)
%get the position of the cursor
pos = get(eventObj,'Position');

%get the handles from root figure
h = groot;
handles = guidata(h.CurrentFigure);

%create text to write next to cursor
output_txt{1,1} = num2str(pos(1));
handles.dataText = output_txt;
guidata(h.CurrentFigure,handles);
end

function pushbuttonLoadSourceFile_Callback(hObject, ~, handles)
%if a file is loaded, check to see if you want new file
if ~isempty(handles.source.filename)
    choice = questdlg('Are you sure you want to load a new file?', ...
        'Exit', ...
        'Yes','No','No');
    switch choice
        case 'Yes'
            %continue down below;
        case 'No'
            return; %don't overwrite anything
    end
end
%choose file
[filename,pathname] = uigetfile('*');
if filename == 0
    return; %empty file
end

%load file
try
[N,~,~] = xlsread([pathname,filename]); 
axes(handles.sourceAxes); cla; hold on;
catch e
    errordlg('Unable to read file');
    return;
end

%initialize variables
handles.source.data     = N;
handles.source.time     = N(:,1);
handles.source.filename = filename(1:end-4);
handles.source.pathname = pathname;
zoom out;

%plot our signals, assume 1st column: time, 2-4 cols: tri-axial data
plot(handles.sourceAxes,N(:,1),N(:,2:4));
set(handles.sourceAxes,'xminortick','on','xlim',[min(N(:,1)) max(N(:,1))]);

%get the default limits from plotting
handles.source.ylimits = get(handles.sourceAxes,'ylim');
handles.source.xlimits = get(handles.sourceAxes,'xlim');

%initialize marker lines and update functions
set(handles.dcm,'DisplayStyle','datatip','Enable','off','UpdateFcn',@onDCM);
if get(handles.radiobuttonSelect,'value');
    set(handles.dcm,'DisplayStyle','datatip','Enable','on','UpdateFcn',@onDCM);
end
set(handles.textSourceFile,'string',filename);
guidata(hObject,handles);
end

function pushbuttonLoadTargetFile_Callback(hObject, ~, handles)
%if a file is loaded, check to see if you want new file
if ~isempty(handles.target.filename)
    choice = questdlg('Are you sure you want to load a new file?', ...
        'Exit', ...
        'Yes','No','No');
    switch choice
        case 'Yes'
            %continue down below;
        case 'No'
            return; %don't overwrite anything
    end
end
%choose file
[filename,pathname] = uigetfile('*');
if filename == 0
    return; %empty file
end

%load file
try
[N,~,~] = xlsread([pathname,filename]); 
axes(handles.targetAxes); cla; hold on;
catch e
    errordlg('Unable to read file');
    return;
end

%initialize variables
handles.target.data     = N;
handles.target.filename = filename(1:end-4);
handles.target.pathname = pathname;

%assume actigraph is in serial time, convert to relative seconds
relativeTime = datevec(N(:,1) - N(1,1));
handles.target.time = relativeTime(:,4) * 3600 + relativeTime(:,5) * 60 + relativeTime(:,6);

%plot our signals, assume 1st column: time, 2-4 cols: tri-axial data
zoom out;
plot(handles.targetAxes,handles.target.time,N(:,2:4));
set(handles.targetAxes,'xminortick','on');

%get the data
handles.target.data = N;

%get the default limits from plotting
handles.target.ylimits = get(handles.targetAxes,'ylim');
handles.target.xlimits = get(handles.targetAxes,'xlim');

%initialize marker lines and update functions
set(handles.dcm,'DisplayStyle','datatip','Enable','off','UpdateFcn',@onDCM);
if get(handles.radiobuttonSelect,'value');
    set(handles.dcm,'DisplayStyle','datatip','Enable','on','UpdateFcn',@onDCM);
end
set(handles.textTargetFile,'string',filename);
guidata(hObject,handles);
end

function pushbuttonApplyMark_Callback(hObject, ~, handles)
if isempty(handles.dataText)
    return;
end
pos = handles.dataText;
a   = get(gca,'tag');
hold on
if strcmp(a,'sourceAxes')
    handles.source.index = find(abs(handles.source.time - str2double(pos)) < 10^-10);
    x = ones(2,1) * handles.source.time(handles.source.index);
    y = [handles.source.ylimits(1) handles.source.ylimits(2)];
    if~isempty(handles.source.mark)
        delete(handles.source.mark)
    end
    handles.source.mark = plot(gca,x,y,'k');
    disp(['Source Position: ' num2str(x(1))]);
elseif strcmp(a,'targetAxes')
    handles.target.index = find(abs(handles.target.time - str2double(pos)) < 10^-10);
    x = ones(2,1) * handles.target.time(handles.target.index);
    y = [handles.target.ylimits(1) handles.target.ylimits(2)];
    if~isempty(handles.target.mark)
        delete(handles.target.mark)
    end
    handles.target.mark = plot(gca,x,y,'k');
    disp(['Target Position: ' num2str(x(1))]);
else
    return;
end

if ~isempty(handles.source.index) && ~isempty(handles.target.index)
   %calculate the shift
   handles.shift = handles.source.time(handles.source.index) - handles.target.time(handles.target.index);
   
   %align the time, take only values in the desired window
   time                  = handles.target.time + handles.shift;
   ind                   = time > 0 & time < max(handles.source.time);
   handles.output        = [];
   handles.output(:,1)   = time(ind);
   handles.output(:,2:4) = handles.target.data(ind,2:4);
   
   %plot on the output axes
   axes(handles.outputAxes); cla;
   plot(handles.output(:,1),handles.output(:,2:4));
end
guidata(hObject,handles);
end

function pushbuttonExport_Callback(~, ~, handles)
%check to make sure we have data to export
if isempty(handles.output)
   display('Please load two files to align');
   return;
end

%filename for exported file
filename = [handles.source.filename(1:end-23) 'actigraph'];
file     = [handles.source.pathname, filename, '.xlsx'];

%write file
startRow         = '1';
startCol         = 'A';
[endRow, endCol] = size(handles.output);
endRow           = num2str(endRow);
ABCstring        = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
endCol           = ABCstring(endCol);
rangeStr         = [startCol startRow ':' endCol endRow];
xlswrite(file,handles.output,rangeStr);
end
