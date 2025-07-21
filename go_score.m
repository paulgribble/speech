function out = go_score(selpath, n_wav)

% go_score : Given a directory name, cycles through all .wav files within that
% directory and plots the audio signal and a spectrogram, and automatically
% identifies the start and end of the sibilant; saves the sample point (in samples) to a file
% with the same filename as the directory, but with a .csv suffix. If the
% function is called with no arguments, brings up a GUI file picker and the
% user is to select the name of the directory. The function both saves the
% sample points to a .csv file and returns an array of sample points as
% output.

if nargin==0
    selpath = uigetdir;
end

if isfolder(selpath)
    file_list = dir(selpath + "/" + "*.wav");
end
if nargin<2
    n_wav = length(file_list);
end
fprintf("found %d .wav files in %s\n", n_wav, selpath)

tmp = strsplit(selpath, filesep);
fname_out = tmp{end} + "_scored" + ".csv";
fprintf("will save sample points to %s\n", fname_out)

sib_start_vec = zeros(n_wav, 1); % Initialize array to store sample points
sib_end_vec   = zeros(n_wav, 1); % Initialize array to store sample points
filename = string.empty;
trial_num = zeros(1,n_wav);
for i=1:n_wav
    fprintf("file %3d/%3d : %s ... \n", i, n_wav, file_list(i).name);
    f = file_list(i).name;
    fname = file_list(i).folder + "/" + f;
    filename(i) = f;
    [y,Fs] = audioread(fname);
    y1 = y(:,1); % from microphone
    y2 = y(:,2); % played over headphones
    t = 0:(1/Fs):(size(y,1)/Fs); t = t(1:end-1)';
    [sib_start,sib_end] = plotWithSkipButton(y1,t,Fs,file_list(i).name);
    if isnan(sib_start)
        sib_start = 0;
        sib_end   = 0;
    end
    sib_start_vec(i) = sib_start; % seconds
    sib_end_vec(i)   = sib_end;   % seconds
    drawnow
    pause(0.350)
end

sib_start_vec = round(sib_start_vec*Fs); % sec to samples
sib_end_vec   = round(sib_end_vec*Fs);   % sec to samples

% write the filenames and sample points to a .csv file
selpath_col = repmat(selpath, n_wav, 1); % Create a cell array with selpath repeated n_wav times
T = table(selpath_col, filename', sib_start_vec, sib_end_vec, 'VariableNames', {'filedir','filename','sib_start','sib_end'});
writetable(T, fname_out, "WriteVariableNames",true);
fprintf("Saved %d rows to %s\n", n_wav, fname_out)

if nargout>0
    out = T;
end


function [sib_start,sib_end] = plotWithSkipButton(y,t,Fs,fname)
    % Create a figure and plot the input vector y
    % get screen size in pixels
    screenSize = get(0, 'ScreenSize');
    % Define figure size (e.g., 600x400 pixels)
    figWidth = 2400;
    figHeight = 800;    % Calculate top-left position
    left = 1;  % Leftmost pixel
    bottom = screenSize(4) - figHeight;  % From top of screen downward
    % Create and position the figure
    fig = figure('Position', [left, bottom, figWidth, figHeight], 'MenuBar','none','ToolBar','none');
    subplot(2,1,1); hold on
    plot(t,y);
    title('Click on the plot or press "Skip"');
    xlabel('TIME (s)');
    ylabel('AUDIO (MIC)');
    colorbar
    xlim([t(1),t(end)])
    title('CLICK CENTRE OF SIBILANT')
    sgtitle(fname, 'Interpreter', 'none')
    subplot(2,1,2); hold on
    spectrogram(y(:,1), 256, 230, 256, Fs, 'yaxis')
    colorbar('eastoutside')
    xlim([t(1),t(end)])
    
    % Create a "Skip" button
    uicontrol('Style', 'pushbutton', 'String', 'Skip', ...
              'Position', [20, 20, 60, 30], ...
              'Callback', @(src, event) skipCallback(fig));

    % Create a "Accept" button
    uicontrol('Style', 'pushbutton', 'String', 'Accept', ...
              'Position', [120, 20, 60, 30], ...
              'Callback', @(src, event) acceptCallback(fig));

    % Set the figure's WindowButtonDownFcn to handle clicks
%    set(fig, 'WindowButtonDownFcn', @(src, event) clickCallback(fig));
    set(fig, 'ToolBar', 'none')

    sound(y, Fs);

    [sib_start, sib_end] = IdentifySibilant(y, Fs);
    subplot(2,1,1)
    p1_start = plot([sib_start,sib_start],get(gca,'ylim'),'g-','linewidth',2);
    p1_end = plot([sib_end,sib_end],get(gca,'ylim'),'r-','linewidth',2);
    subplot(2,1,2)
    p2_start = plot([sib_start,sib_start],get(gca,'ylim'),'g-','linewidth',2);
    p2_end = plot([sib_end,sib_end],get(gca,'ylim'),'r-','linewidth',2);

    % set up UI for draggine the lines
    setupLinkedDraggableLine(p1_start, p2_start);
    setupLinkedDraggableLine(p1_end, p2_end);

    % Wait for user input
    uiwait(fig);

    function setupLinkedDraggableLine(topLine, linkedLine)
        set(topLine, 'ButtonDownFcn', @(src, event) startLinkedDragX(src, linkedLine));
    end

    function startLinkedDragX(topLine, linkedLine)
        fig = ancestor(topLine, 'figure');
        ax = ancestor(topLine, 'axes');
    
        pt = get(ax, 'CurrentPoint');
        x0_top = get(topLine, 'XData');
        x0_linked = get(linkedLine, 'XData');
    
        data.topLine = topLine;
        data.linkedLine = linkedLine;
        data.ax = ax;
        data.x0_top = x0_top;
        data.x0_linked = x0_linked;
        data.startX = pt(1,1);
    
        set(fig, 'WindowButtonMotionFcn', @(~,~) dragLinkedLineX(data));
        set(fig, 'WindowButtonUpFcn', @(~,~) stopDragLine(fig));
    end
    
    function dragLinkedLineX(data)
        pt = get(data.ax, 'CurrentPoint');
        dx = pt(1,1) - data.startX;
    
        % Move both lines
        set(data.topLine, 'XData', data.x0_top + dx);
        set(data.linkedLine, 'XData', data.x0_linked + dx);
        drawnow;
    end
    
    function stopDragLine(fig)
        set(fig, 'WindowButtonMotionFcn', '');
        set(fig, 'WindowButtonUpFcn', '');
    end

    
    % Nested function for skip button
    function skipCallback(~)
        sib_start = NaN; % Return NaN if skip is pressed
        sib_end   = NaN; % Return NaN if skip is pressed
        uiresume(fig);   % Resume the figure
        close(fig);      % Close the figure
    end

    % Nested function for skip button
    function acceptCallback(~)
        sib_start = p1_start.XData(1);
        sib_end   = p1_end.XData(1);
        uiresume(fig);   % Resume the figure
        close(fig);      % Close the figure
    end

end

end
