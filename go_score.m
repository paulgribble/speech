function out = go_score(selpath)

% go_score : Given a directory name, cycles through all .wav files within that
% directory and plots the audio signal and a spectrogram, and allows the
% user to click on a time point; saves the sample point (in samples) to a file
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
n_wav = length(file_list);
fprintf("found %d .wav files in %s\n", n_wav, selpath)

tmp = strsplit(selpath, filesep);
fname_out = tmp{end} + "_scored" + ".csv";
fprintf("will save sample points to %s\n", fname_out)

scoredPoints = zeros(n_wav, 1); % Initialize array to store sample points
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
    g1 = plotWithSkipButton(y1,t,Fs,file_list(i).name);
    if isnan(g1)
        g1 = 0;
    end
    scoredPoints(i) = round(g1 * Fs); % samples
    drawnow
    pause(0.350)
end

% write the filenames and sample points to a .csv file
selpath_col = repmat(selpath, n_wav, 1); % Create a cell array with selpath repeated n_wav times
T = table(selpath_col, filename', scoredPoints, 'VariableNames', {'filedir','filename','scoredpoints'});
writetable(T, fname_out, "WriteVariableNames",true);

if nargout>0
    out = T;
end


function xLocation = plotWithSkipButton(y,t,Fs,fname)
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
    subplot(2,1,1)
    plot(t,y);
    title('Click on the plot or press "Skip"');
    xlabel('TIME (s)');
    ylabel('AUDIO (MIC)');
    colorbar
    xlim([t(1),t(end)])
    title('CLICK CENTRE OF SIBILANT')
    sgtitle(fname, 'Interpreter', 'none')
    subplot(2,1,2)
    spectrogram(y(:,1), 256, 230, 256, Fs, 'yaxis')
    colorbar('eastoutside')
    xlim([t(1),t(end)])
    
    % Create a "Skip" button
    uicontrol('Style', 'pushbutton', 'String', 'Skip', ...
              'Position', [20, 20, 60, 30], ...
              'Callback', @(src, event) skipCallback(fig));

    % Set the figure's WindowButtonDownFcn to handle clicks
    set(fig, 'WindowButtonDownFcn', @(src, event) clickCallback(fig));
    set(fig, 'ToolBar', 'none')

    sound(y, Fs);

    % Wait for user input
    uiwait(fig);

    % Nested function for skip button
    function skipCallback(~)
        xLocation = NaN; % Return NaN if skip is pressed
        uiresume(fig);   % Resume the figure
        close(fig);      % Close the figure
    end

    % Nested function for mouse click
    function clickCallback(~)
        % Get the current point of the mouse click
        cp = get(gca, 'CurrentPoint');
        xLocation = cp(1, 1); % Get the x location

        % Draw a vertical line at the clicked x location
        hold on;
        line([xLocation, xLocation], ylim, 'Color', 'r', 'LineStyle', '--');

        % Resume the figure
        uiresume(fig);
        close(fig); % Close the figure after selection
    end

end

end
