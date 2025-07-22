function out = go_score(selpath, n_wav)
% go_score: Scores sibilant regions in audio files.
%
% Given a directory containing `.wav` files, this function:
%   - Plots each file's waveform and spectrogram.
%   - Automatically identifies the sibilant region.
%   - Allows user adjustment via GUI.
%   - Saves the sibilant start/end (in samples) to a CSV file.
%
% Usage:
%   go_score()              % Prompts user to select folder.
%   go_score(folder_path)   % Uses the specified folder.
%   go_score(folder_path, N)% Only process the first N wav files.
%
% Output:
%   Returns a table with file paths, names, and sibilant start/end in samples.

    if nargin == 0
        selpath = uigetdir;
    end

    if isfolder(selpath)
        file_list = dir(fullfile(selpath, "*.wav"));
    else
        error("Provided path is not a folder.");
    end

    if nargin < 2
        n_wav = length(file_list);
    end

    fprintf("Found %d .wav files in %s\n", n_wav, selpath);

    tmp = strsplit(selpath, filesep);
    fname_out = tmp{end} + "_scored.csv";
    fprintf("Will save sample points to %s\n", fname_out);

    sib_start_vec = nan(n_wav, 1);
    sib_end_vec   = nan(n_wav, 1);
    filename      = strings(n_wav, 1);

    quit_flag = false;

    for i = 1:n_wav
        fprintf("File %3d/%3d : %s\n", i, n_wav, file_list(i).name);
        fname = fullfile(file_list(i).folder, file_list(i).name);
        filename(i) = file_list(i).name;

        [y, Fs] = audioread(fname);
        y1 = y(:, 1); % Mic input
        t = (0:(size(y,1)-1)) / Fs;

        [sib_start, sib_end, quit_flag] = plotWithSkipButton(y1, t, Fs, file_list(i).name);
        if quit_flag
            fprintf("User pressed QUIT. Aborting...\n");
            break;
        end

        if isnan(sib_start)
            sib_start = 0;
            sib_end   = 0;
        end

        sib_start_vec(i) = sib_start;
        sib_end_vec(i)   = sib_end;

        drawnow;
        pause(0.35);
    end

    sib_start_vec = round(sib_start_vec * Fs);
    sib_end_vec   = round(sib_end_vec * Fs);

    selpath_col = repmat(selpath, n_wav, 1);
    T = table(selpath_col, filename, sib_start_vec, sib_end_vec, ...
        'VariableNames', {'filedir', 'filename', 'sib_start', 'sib_end'});

    writetable(T, fname_out);
    fprintf("Saved %d rows to %s\n", n_wav, fname_out);

    if nargout > 0
        out = T;
    end
end

function [sib_start, sib_end, quit_flag] = plotWithSkipButton(y, t, Fs, fname)
% GUI tool to visualize audio, identify sibilant region, and allow drag adjustment.

    quit_flag = false;

    screenSize = get(0, 'ScreenSize');
    fig = figure('Position', [1, screenSize(4)-800, 2400, 800], ...
                 'MenuBar', 'none', 'ToolBar', 'none');

    subplot(2,1,1); hold on;
    plot(t, y);
    title('CLICK CENTRE OF SIBILANT');
    xlabel('TIME (s)');
    ylabel('AUDIO (MIC)');
    xlim([t(1), t(end)]);
    sgtitle(fname, 'Interpreter', 'none');

    subplot(2,1,2); hold on;
    spectrogram(y, 256, 230, 256, Fs, 'yaxis');
    xlim([t(1), t(end)]);
    colorbar('eastoutside');

    uicontrol('Style', 'pushbutton', 'String', 'Skip', ...
              'Position', [20, 20, 60, 30], ...
              'Callback', @(~,~) skipCallback());
    uicontrol('Style', 'pushbutton', 'String', 'Accept', ...
              'Position', [120, 20, 60, 30], ...
              'Callback', @(~,~) acceptCallback());
    uicontrol('Style', 'pushbutton', 'String', 'Quit', ...
              'Position', [220, 20, 60, 30], ...
              'Callback', @(~,~) quitCallback());

    sound(y, Fs);

    [sib_start, sib_end] = IdentifySibilant(y, Fs);

    subplot(2,1,1);
    p1_start = plot([sib_start, sib_start], ylim, 'g-', 'LineWidth', 2);
    p1_end   = plot([sib_end, sib_end], ylim, 'r-', 'LineWidth', 2);
    subplot(2,1,2);
    p2_start = plot([sib_start, sib_start], ylim, 'g-', 'LineWidth', 2);
    p2_end   = plot([sib_end, sib_end], ylim, 'r-', 'LineWidth', 2);

    setupLinkedDraggableLine(p1_start, p2_start);
    setupLinkedDraggableLine(p1_end, p2_end);

    uiwait(fig);

    function skipCallback()
        sib_start = NaN;
        sib_end   = NaN;
        uiresume(fig);
        close(fig);
    end

    function acceptCallback()
        sib_start = p1_start.XData(1);
        sib_end   = p1_end.XData(1);
        uiresume(fig);
        close(fig);
    end

    function quitCallback()
        sib_start = NaN;
        sib_end   = NaN;
        quit_flag = true;
        uiresume(fig);
        close(fig);
    end

    function setupLinkedDraggableLine(topLine, linkedLine)
        set(topLine, 'ButtonDownFcn', @(~,~) startLinkedDragX(topLine, linkedLine));
    end

    function startLinkedDragX(topLine, linkedLine)
        fig = ancestor(topLine, 'figure');
        ax = ancestor(topLine, 'axes');
        pt = get(ax, 'CurrentPoint');
        x0_top = get(topLine, 'XData');
        x0_linked = get(linkedLine, 'XData');

        data = struct('topLine', topLine, ...
                      'linkedLine', linkedLine, ...
                      'ax', ax, ...
                      'x0_top', x0_top, ...
                      'x0_linked', x0_linked, ...
                      'startX', pt(1,1));

        set(fig, 'WindowButtonMotionFcn', @(~,~) dragLinkedLineX(data));
        set(fig, 'WindowButtonUpFcn', @(~,~) stopDragLine(fig));
    end

    function dragLinkedLineX(data)
        pt = get(data.ax, 'CurrentPoint');
        dx = pt(1,1) - data.startX;
        set(data.topLine, 'XData', data.x0_top + dx);
        set(data.linkedLine, 'XData', data.x0_linked + dx);
        drawnow;
    end

    function stopDragLine(fig)
        set(fig, 'WindowButtonMotionFcn', '');
        set(fig, 'WindowButtonUpFcn', '');
    end
end

function [s_start, s_end] = IdentifySibilant(source, sr)
% IdentifySibilant - Identify the start and end of a sibilant
%
% usage:  [s_start, s_end] = IdentifySibilant(source, sr)

    wSize = 30;              % RMS and ZC window size in ms
    RMSthr = 0.05;           % low energy threshold

    ws = round(wSize * sr / 1000);
    rms = smooth(envelope(source, ws, 'rms'), ws);
    rms = rms ./ max(rms);

    ws2 = ceil(ws / 2);
    s = [zeros(ws2,1); source; zeros(ws2,1)];
    zc = filter(rectwin(ws), 1, [0; abs(diff(s >= 0))]);
    zc = smooth(zc(ws2*2+1:end), ws);
    zc = zc ./ max(abs(zc));

    zc(rms < RMSthr) = 0;

    idx = find(zc > 0.5);
    if isempty(idx)
        s_start = 0;
        s_end = 0;
    else
        hts = idx([1 end]);
        ht = (hts - 1) / sr;
        s_start = ht(1);
        s_end = ht(2);
    end
end
