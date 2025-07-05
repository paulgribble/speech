function xLocation = plotWithSkipButton(y,t,Fs,fname)
    % Create a figure and plot the input vector y
    fig = figure;
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

