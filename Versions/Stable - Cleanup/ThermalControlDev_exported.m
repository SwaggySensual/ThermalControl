classdef ThermalControlDev_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        AvailableCameras               matlab.ui.control.ListBox
        AvailableCamerasLabel          matlab.ui.control.Label
        StopStreamButton               matlab.ui.control.Button
        StartStream                    matlab.ui.control.Button
        DiscoverDevices                matlab.ui.control.Button
        TabGroup3                      matlab.ui.container.TabGroup
        ScreenshotTab                  matlab.ui.container.Tab
        ScreenshotFileName             matlab.ui.control.EditField
        FileNameEditFieldLabel_3       matlab.ui.control.Label
        ScreenshotPath                 matlab.ui.control.EditField
        ScreenshotPathLabel            matlab.ui.control.Label
        BrowseScreenshotButton         matlab.ui.control.Button
        TakeIS2ScreenshotButton        matlab.ui.control.Button
        CSVTab                         matlab.ui.container.Tab
        CSVFileName                    matlab.ui.control.EditField
        CSVFileNameLabel               matlab.ui.control.Label
        CSVFilePath                    matlab.ui.control.EditField
        CSVFilePathLabel               matlab.ui.control.Label
        CSVBrowseButton                matlab.ui.control.Button
        ExporttoCSVButton              matlab.ui.control.Button
        IS3VideoTab                    matlab.ui.container.Tab
        MovieLength                    matlab.ui.control.NumericEditField
        LengthmSEditFieldLabel         matlab.ui.control.Label
        RecordFileName                 matlab.ui.control.EditField
        FileNameEditFieldLabel_4       matlab.ui.control.Label
        RecordPath                     matlab.ui.control.EditField
        RecordingPathLabel             matlab.ui.control.Label
        BrowseRecordButton             matlab.ui.control.Button
        RecordIS3VideoButton           matlab.ui.control.Button
        TabGroup                       matlab.ui.container.TabGroup
        LiveFeedTab                    matlab.ui.container.Tab
        LiveFeedAxes                   matlab.ui.control.UIAxes
        FilteredImageTab               matlab.ui.container.Tab
        FilteredAxes                   matlab.ui.control.UIAxes
        TabGroup2                      matlab.ui.container.TabGroup
        ServoControlTab                matlab.ui.container.Tab
        StartTCButton                  matlab.ui.control.Button
        ControllerSettingsPanel        matlab.ui.container.Panel
        PrinterSpeedKnob               matlab.ui.control.DiscreteKnob
        TemperatureSettingsTab         matlab.ui.container.Tab
        RangeSwitch                    matlab.ui.control.Switch
        RangeSwitchLabel               matlab.ui.control.Label
        TrackPointTemperaturePanel     matlab.ui.container.Panel
        Y                              matlab.ui.control.NumericEditField
        CursorYLabel                   matlab.ui.control.Label
        X                              matlab.ui.control.NumericEditField
        XLabel_2                       matlab.ui.control.Label
        CurrentTemp                    matlab.ui.control.NumericEditField
        CursorTempLabel                matlab.ui.control.Label
        ExportDatacsvButton            matlab.ui.control.Button
        ROISizeDropDown                matlab.ui.control.DropDown
        ROISizeDropDownLabel           matlab.ui.control.Label
        TrackPointTemperatureButton    matlab.ui.control.Button
        NUCCommands                    matlab.ui.control.DropDown
        NonUniformityCorrectionControlLabel  matlab.ui.control.Label
        SendNUCCommandButton           matlab.ui.control.Button
        EBTConfigurationPanel          matlab.ui.container.Panel
        EBTTempUnit                    matlab.ui.control.DropDown
        TemperatureUnitLabel           matlab.ui.control.Label
        ConfigureEBTButton             matlab.ui.control.Button
        EBTTransmission                matlab.ui.control.NumericEditField
        TransmissionEditFieldLabel_2   matlab.ui.control.Label
        EBTBGTemp                      matlab.ui.control.NumericEditField
        BGTempEditFieldLabel_2         matlab.ui.control.Label
        EBTEmissivity                  matlab.ui.control.NumericEditField
        EmissivityEditFieldLabel_2     matlab.ui.control.Label
        NozzleFilteringTab             matlab.ui.container.Tab
        LowestFilteredTempPercentile   matlab.ui.control.Spinner
        LowestFilteredTemperaturePercentileSpinnerLabel  matlab.ui.control.Label
        CreateTemplate                 matlab.ui.control.Button
        TemplatePreviewAxes            matlab.ui.control.UIAxes
        LayerAnalysisTab               matlab.ui.container.Tab
        LoadedFile                     matlab.ui.control.EditField
        LoadedFileLabel                matlab.ui.control.Label
        ModLayerTime                   matlab.ui.control.NumericEditField
        CurrentLayerLabel_6            matlab.ui.control.Label
        ModFeedrate                    matlab.ui.control.NumericEditField
        CurrentLayerLabel_5            matlab.ui.control.Label
        OGLayerTime                    matlab.ui.control.NumericEditField
        CurrentLayerLabel_4            matlab.ui.control.Label
        OGFeedrate                     matlab.ui.control.NumericEditField
        CurrentLayerLabel_3            matlab.ui.control.Label
        ToolpathDist                   matlab.ui.control.NumericEditField
        CurrentLayerLabel_2            matlab.ui.control.Label
        LoadMPFfileButton              matlab.ui.control.Button
        LayerCounter                   matlab.ui.control.NumericEditField
        CurrentLayerLabel              matlab.ui.control.Label
        TemperatureUnits               matlab.ui.control.DropDown
        TemperatureUnitsDropDownLabel  matlab.ui.control.Label
        FocusDistance                  matlab.ui.control.Slider
        FocusDistancemmSliderLabel     matlab.ui.control.Label
        TemperatureTracker             matlab.ui.control.UIAxes
    end

    %Above Code is all MATLAB Generated and specifies the GUI components
    properties (Access = private)
        
        %The properties below are used to pass data throughout the application
        TempArray;
        IRImage;
        enableROI;
        maskedData;
        maxArray;
        minArray;
        currentTempArray = []; % Array to store [Time, Temperature]
        count;
        maxLine;
        minLine;
        pointLine;
        addROIPoints;

        %Handlers
        ThermalPlotHandle; %Handles the thermal data in the UIAxes
        FilteredPlotHandle; %Handles the thermal data in the UIAxes
    end
    
    properties (Access = public)
        SystemState = 'IDLE';
        TargetTemp = 130;
        RoomTemp = 25;
        TripwireVisual;                         % Handler for the Tripwire visual
        CurrentLayer = 0;
        DecayCurveHandle;
        BlurFactor = 1.5;
        minRPM = 5;
        layerWidth;
        layerHeight;
        materialNumber = 1958;

        %Template Matching
        NozzleTemplate;                         % Raw template image (matrix)
        TemplateRect;                           % Rectangle [xmin ymin width height]
        StackHeight = 25;                       % Number of templates to be saved, must be an odd number
        NozzleTemplateStack = {};               % cell array of scaled templates
        NozzleTemplateScales = [];              % vector of scales (double)
        TipCoordinates;                         % Will hold an [A x 2] matrix of [X, Y] points storing the tip location for every scaled template, being A template stack height
        ExtruderTip;                            % Visual marker for the tracked nozzle tip
        CurrentScaleIdx;
        LastTemplateRStart                      % Top edge of the last match
        LastTemplateCStart                      % Left edge of the slast match
        LastTemplateH                           % Height of the last match
        LastTemplateW                           % Width of the last match
        
        %G-code data
        layerLengths;
        layerFeedrates;
        layerTimes;

        %Thermal Filter
        live_TipX;
        live_TipY;
        DiskStrel;

        startTime;                          % To calculate "Seconds since tracking started"
        ROIBox;                             % Stores the graphical rectangle object
        FilteredImageRaw;                   % Needed for ThermalFilter masking function to work%To clean up the thermal Filter Mask
        FilteredImageBlur;
        FilteredImageCarved;
        trackPointTemp;
        LiveFeedROIBox;
        FilteredROIBox;

        % --- Tracking Points ---
        DroppedPointsX;                     % Stores the history of X coordinates
        DroppedPointsY;                     % Stores the history of Y coordinates
        TrailIndex = 0;                     % Keeps track of where to drop the next point
        DroppedPointsVisual;                % The UI graphic object for the trail
        TempHistory;                        % 20 rows (points) x 20 columns (temp history)
        MatrixSize = 2000;                  % Defines the size of the TempMatrix and GradTempMatrix, can be modified
        PointAges;                          % Tracks how many frames a point has existed
        TempMatrix;                         % The live matrix
        TimeMatrix;                         % Matrix holding the elapsed time of every point
        GradTempMatrix;                     % The completed points matrixGrad
        GradTimeMatrix;
        BirthTimes;
        PointsPerLayer = 0;                 % Stores 'n'
        LayerMatrix;
        GradAge = 10;
        PreviousLayerCounter = 000;          % Used to detect when the layer ticks up
        DropIndex = 0;                      %Important: Initialize indexes. It cannot be NaN
        GradIndex = 0;

        % Tripwire State
        TripwireThreshold = 180; 
        IsNozzleInTripwire = false;
        TripwirePassCount = 0;
        MPFFilePath;        %Stores the path for the loaded .mpf

        %FPS Tracker
        LastFrameTime;      % Stores the precise 'tic' clock from the previous frame
        LiveFPSHandle;      % Graphic handle for the live feed text overlay
        FilteredFPSHandle;  % Graphic handle for the filtered feed text overlay
    end

    methods (Access = public)
        %Used to provide feedback when the recording is completed
        function TriggerCallback(~,~,~, app)
            app.RecordIS3VideoButton.Text = 'Record IS3 Video';
        end
    end
    
    methods (Access = private)

        %This application runs the "Streaming Loop" on a timer that executes at a specified interval (currently every 330 mS)
        %This is the function that the timer executes each iteration. It contains all the function calls and manipulation 
        %that requires streaming data (i.e. updates the image, etc.)
        function FrameCallback(app,~, ~)    
            try   
                %Get the temperature data and the IR Image from the camera
                [app.TempArray, app.IRImage] = ToolkitFunctions.GetData(app.TemperatureUnits.Value);

                % Run manual point-tracking system if active - IN DEVELOPMENT
                %CVFunctions.trackManualPoint(app, app.TempArray);

                % --- Track Point algorithm ---
                %Graph the point specified by the X and Y Edit boxes
                if app.trackPointTemp
                    % Read the current value from the DropDown menu.
                    % Because DropDowns output text (like "3"), we must convert it to a double!
                    boxSize = str2double(app.ROISizeDropDown.Value);
                    % 2. Calculate the offset (e.g., a 3x3 box reaches 1 pixel out from the center)
                    offset = floor(boxSize / 2);
                    % 3. Get the center coordinates (Assuming app.Y.Value and app.X.Value are ready)
                    cY = app.Y.Value;
                    cX = app.X.Value;
                    % 4. Get the maximum limits of your thermal array
                    [maxRows, maxCols] = size(app.TempArray);
                    % 5. Calculate the bounding box, clamping to the edges so it never crashes
                    rowStart = max(1, cY - offset);
                    rowEnd   = min(maxRows, cY + offset);
                    colStart = max(1, cX - offset);
                    colEnd   = min(maxCols, cX + offset);
                    % Move the box to the new location and size
                    app.LiveFeedROIBox.Position = [colStart, rowStart, boxSize, boxSize];
                    app.LiveFeedROIBox.Visible = 'on'; % Make sure it is visible
                    app.FilteredROIBox.Position = [colStart, rowStart, boxSize, boxSize];
                    app.FilteredROIBox.Visible = 'on'; % Make sure it is visible
                    % 6. Extract that specific block of pixels from the array
                    roiArray = app.TempArray(rowStart:rowEnd, colStart:colEnd);
                    % 7. Calculate the mean of all pixels in that block
                    currentTemp = double(mean(roiArray, 'all'));
                    deltaT = currentTemp - app.EBTBGTemp.Value; %Substract the room temperature from the temperature reading to determine DeltaT
                    % Store the new data point [Time, Temp] (Pedro 02/03/2026)
                    % Calculate elapsed time in seconds
                    elapsedTime = seconds(datetime('now') - app.startTime);
                    % We append a new row to the bottom of the array
                    app.currentTempArray(end+1, :) = [elapsedTime, currentTemp, deltaT];
                    %Updates the graph with the new array
                    addpoints(app.pointLine, elapsedTime, currentTemp);
                    app.CurrentTemp.Value = currentTemp;
                end

                switch app.SystemState
                    case 'IDLE'
                        
                    case 'PRINT_STARTED'
                        % Read the Layer Tripwire
                        CVFunctions.LayerTripwire(app, app.TempArray); %Uncomment when needed
                       
                        %Apply the filtering mask (legacy name: SSPV7)
                        [app.FilteredImageRaw, app.FilteredImageBlur] = CVFunctions.ThermalFilter(app.TempArray, app.LowestFilteredTempPercentile.Value, app.RoomTemp);

                        %Run the TemplateTracking algorithm and the Tracking Points
                        app.FilteredImageCarved = CVFunctions.TemplateTracking(app, app.FilteredImageRaw);
                        CVFunctions.TrackingPoints(app, app.FilteredImageRaw, app.FilteredImageCarved);

                        % ---> THE RISING EDGE EVENT COORDINATOR <---
                        if app.CurrentLayer > app.PreviousLayerCounter
                            disp(['*** LAYER ', num2str(app.PreviousLayerCounter), ' COMPLETED ***\n']);
                            %disp(app.GradIndex);
                            %disp(app.GradAge);
                            
                            % A. Process the completed layer (if we have graduated points)
                            if app.GradIndex > 0
                                % 1. Extract the clean data
                                validTemp = app.GradTempMatrix(1:app.GradIndex, :);
                                validTime = app.GradTimeMatrix(1:app.GradIndex, :);
                                
                                % 2. Send it to the calculator
                                DataAnalysisFunctions.CalculateDynamicFeedrate(app, validTemp, validTime);
                                
                                % 3. Reset the paste pointer for the next batch
                                app.GradIndex = 0;

                            else
                                fprintf('No graduated points available\n');
                            end
                            
                            % B. Lock in the target 'n' for the newly started layer
                            app.GradAge = app.PointsPerLayer;
                            
                            % C. Pre-allocate the fresh matrices for the new target age
                            if app.GradAge > 0
                                app.GradTempMatrix = NaN(app.MatrixSize, app.MatrixSize);
                                app.GradTimeMatrix = NaN(app.MatrixSize, app.MatrixSize);
                            end
                            
                            % D. Reset the live drop counter for the new layer
                            app.PointsPerLayer = 0;
                            
                            % E. Update the UI Displays
                            app.LayerCounter.Value = max(1, double(app.CurrentLayer));
                            DataAnalysisFunctions.updateLayerDataDisplay(app);
                            
                            % F. Close the Gate
                            app.PreviousLayerCounter = app.CurrentLayer;
                        end
                end
                
                %--- LIVE FEED ---
                %Displays the original (or edited) IR image in the UIAxes
                % Update the pixels instantly
                app.ThermalPlotHandle.CData = app.IRImage;

                %--- FILTER IMAGE ---
                %Displays the Filtered image on the second tab
                app.FilteredPlotHandle.CData = app.FilteredImageCarved;

                % --- Trigger FPS Diagnostics ---
                DataAnalysisFunctions.updateFPSTracker(app, app.LiveFeedAxes, true);       % Tracks the raw live frame rate

                drawnow limitrate; % Forces the UI to flush its graphics queue

            catch ME
                disp(ME);
                for i = 1:length(ME.stack)
                    fprintf('Level %d: %s at line %d\n', i, ME.stack(i).name, ME.stack(i).line);
                end
            end    
        end
        
        %Creates the Streaming Loop Timer
        function StartStreamTimer(app, ~)
            t = timer('TimerFcn', {@app.FrameCallback}, 'ExecutionMode', 'fixedSpacing', 'Period', 0.2);
            start(t);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            %Load the required .DLL files
            ToolkitFunctions.LoadAssemblies();

            % 1. Reset all counters and indexes back to zero
            app.PointsPerLayer = 0;
            app.GradAge = 0;
            app.DropIndex = 0;
            app.GradIndex = 0;
            
            % 2. Flush the heavy 2D matricesPointLength
            app.TempMatrix(:) = NaN;
            app.TimeMatrix(:) = NaN;
            app.GradTempMatrix(:) = NaN;
            app.GradTimeMatrix(:) = NaN;
            
            % 3. Flush the 1D tracking arrays
            %app.PointLength(:) = 0;
            app.BirthTimes(:) = NaN;
            app.DroppedPointsX(:) = NaN;
            app.DroppedPointsY(:) = NaN;

            %INITIALIZE VARIABLES
            app.TripwirePassCount = 0;
            app.CurrentLayer = 1;
            app.PreviousLayerCounter = 1; % Prevents the phantom first-frame trigger

            % --- Tracking matrix pre-allocation ---
            % 2D Data Matrices
            app.TempMatrix       = NaN(app.MatrixSize, app.MatrixSize);
            app.TimeMatrix       = NaN(app.MatrixSize, app.MatrixSize);
            app.GradTempMatrix   = NaN(app.MatrixSize, app.MatrixSize);
            app.GradTimeMatrix   = NaN(app.MatrixSize, app.MatrixSize);
            
            % 1D Tracking Arrays
            %app.PointLength      = zeros(app.MatrixSize, 1);
            app.BirthTimes       = NaN(app.MatrixSize, 1);
            app.DroppedPointsX   = NaN(app.MatrixSize, 1);
            app.DroppedPointsY   = NaN(app.MatrixSize, 1);
            
            % Reset our tracking pointer indexes
            app.DropIndex = 0;
            app.GradIndex = 0;

            %INITIALIZE VARIABLES
            app.TripwirePassCount = 0;
            app.CurrentLayer = 1;
            app.PreviousLayerCounter = 1; % Prevents the phantom first-frame trigger

            % --- WINDOW SIZING & POSITIONING ---
            % 1. Get the usable screen size of the current monitor [x, y, width, height]
            screenSize = get(0, 'ScreenSize');
            screenHeight = screenSize(4);
            
            % 2. Get the current app dimensions
            appPos = app.UIFigure.Position; 
            
            % 3. Check if the app height exceeds the screen height (leaving 80px for the Windows Taskbar)
            if appPos(4) > (screenHeight - 80)
                % Calculate a scale factor to shrink it just enough to fit
                scaleFactor = (screenHeight - 80) / appPos(4);
                
                % Apply the scale factor to both width and height to keep aspect ratio
                app.UIFigure.Position(3) = appPos(3) * scaleFactor;
                app.UIFigure.Position(4) = appPos(4) * scaleFactor;
            end
            
            % 4. Force the window to spawn exactly in the center of the screen
            movegui(app.UIFigure, 'center');

            %Tracking matrix pre-allocation
            app.TempMatrix = NaN(app.MatrixSize, app.MatrixSize);
            app.PointAges   = zeros(app.MatrixSize, 1);
            % Reset our tracking pointer index
            app.TrailIndex = 0;

            %Create a DiskStrel to clean up the Thermal filter mask
            app.DiskStrel = strel('disk', 6);

            %Create a blank AXIS and save the handle (Pedro)
            app.LiveFeedAxes.XAxis.Visible = 'off';
            app.LiveFeedAxes.YAxis.Visible = 'off';
            app.ThermalPlotHandle = imagesc(app.LiveFeedAxes, zeros(480, 640)); %Create a blank dummy image (480x640) and SAVE THE HANDLE
            axis(app.LiveFeedAxes, 'image');                                    %Keep the aspect ratio exactly 1:1 so pixels are perfect squares
            app.FilteredAxes.CLim = [0, 250];       % Lock the color limits
            app.FilteredAxes.CLimMode = 'manual';
            app.ThermalPlotHandle.ButtonDownFcn = createCallbackFcn(app, @AxesButtonDown, true); % Link the click event to your custom function
            % Apply the thermal colormap to the Live Feed axis

            %Create a blank AXIS and save the handle (Pedro)
            app.FilteredAxes.XAxis.Visible = 'off';
            app.FilteredAxes.YAxis.Visible = 'off';
            app.FilteredPlotHandle = imagesc(app.FilteredAxes, zeros(480, 640)); %Create a blank dummy image (480x640) and SAVE THE HANDLE
            axis(app.FilteredAxes, 'image');                                    %Keep the aspect ratio exactly 1:1 so pixels are perfect squares
            app.FilteredAxes.CLim = [0, 250]; % Lock the color limits 
            app.FilteredAxes.CLimMode = 'manual';
            app.FilteredPlotHandle.ButtonDownFcn = createCallbackFcn(app, @AxesButtonDown, true); % Link the click event to your custom function
            % Apply the thermal colormap to the Live Feed axis
            colormap(app.FilteredAxes, 'turbo');


            % Initialize the tracking marker (Hidden until data arrives)
            app.ExtruderTip = line(app.FilteredAxes, ...
                'XData', [], 'YData', [], ...
                'LineStyle', 'none', ...
                'Marker', '+', ...             % Use a crosshair shape
                'MarkerSize', 10, ...
                'LineWidth', 1, ...
                'Color', [1 0 0]);           

            % Initialize the trail markers (Hidden via NaN until points are dropped)
            app.DroppedPointsVisual = line(app.FilteredAxes, ...
                'XData', app.DroppedPointsX, ...
                'YData', app.DroppedPointsY, ...
                'LineStyle', 'none', ...
                'Marker', '+', ...             
                'MarkerSize', 6, ...           
                'LineWidth', 1, ...
                'Color', [1 0 0]);             
            
            % Create a floating rectangle on the Filtered Axes
            % Position format is [x, y, width, height]
            app.LiveFeedROIBox = rectangle(app.LiveFeedAxes, ...
                'Position', [1, 1, 10, 10], ... 
                'EdgeColor', [50/255, 205/255, 50/255], ... % Your RGB Lime Green
                'LineWidth', 1, ...
                'Visible', 'off'); % Hide it initially
            
            % Create a floating rectangle on the Filtered Axes
            % Position format is [x, y, width, height]
            app.FilteredROIBox = rectangle(app.FilteredAxes, ...
                'Position', [1, 1, 10, 10], ... 
                'EdgeColor', [50/255, 205/255, 50/255], ... % Your RGB Lime Green
                'LineWidth', 1, ...
                'Visible', 'off'); % Hide it initially

            % Tripwire line visual
            app.TripwireVisual = line(app.FilteredAxes, ...
                'XData', [0 0], 'YData', [0 0], ... % Dummy coordinates to start
                'Color', [50/255, 205/255, 50/255], ... % Lime Green (Idle)
                'LineWidth', 1, ...
                'Visible', 'off'); % Hidden until the stream starts
            
            %Begin searching for cameras at startup
            app.AvailableCameras.Items = "Starting";
            availableCameras = ToolkitFunctions.DiscoverDevices();
            app.AvailableCameras.Items = availableCameras;

            %Automatically try to Start Streaming
            if strcmp(app.AvailableCameras.Items, "No camera found!")
                fig = uifigure('Position',[500 500 370 170]);
                uialert(fig, "No camera found. Please check the connection!", ...
                    'Warning','Icon','warning','CloseFcn',@(src, event) close(fig));
                return;
            else

                %Start the camera stream 
                fig = uifigure('Position',[500 500 370 170]);
                dialog = uiprogressdlg(fig,'Title','Please Wait...', 'Message','Configuring CameraStream');

                dialog.Value = 0.55;
                ToolkitFunctions.StartStream();

                dialog.Value = 0.8;
                dialog.Message = 'CameraStream configured';
                dialog.Value = 1;
                close(dialog); close(fig);
                
                app.StartStreamTimer();
            end

            %Set Second Range at startup
            ToolkitFunctions.SetSecondRange();
            app.RangeSwitch.Value = 'Second';
            
            %Initialise EBT configuration (EBT = Emissitivy, Background, Transmission)
            app.EBTEmissivity.Value = 0.96;
            app.EBTBGTemp.Value = 21;
            app.EBTTempUnit.Value = "Celsius";
            app.EBTTransmission.Value = 100;
            
            % --- AUTO-LOAD LAST USED MPF FILE ---
            % 1. Check if the preference exists from a previous session
            if ispref('ThermalControlApp', 'LastMPFFilePath')
                lastFile = getpref('ThermalControlApp', 'LastMPFFilePath');
                
                % 2. Safety Check: Verify the file wasn't deleted or moved
                if isfile(lastFile)
                    try
                        % Update the UI fields
                        app.MPFFilePath.Value = lastFile;
                        [~, fileNameOnly, ~] = fileparts(lastFile);             
                        app.LoadedFile.Value = fileNameOnly;
                        
                        % Parse the data just like the button does
                        [app.layerLengths, app.layerFeedrates, app.layerTimes] = DataAnalysisFunctions.ParseMPFLayers(app);
                        DataAnalysisFunctions.updateLayerDataDisplay(app); %Update the field texts in the GUI
                        
                        disp(['Successfully auto-loaded previous MPF: ', fileNameOnly]);
                        
                    catch ME
                        disp(['Failed to auto-load previous MPF. Reason: ', ME.message]);
                    end
                else
                    disp('Previous MPF file was moved or deleted. Waiting for user input.');
                end
            end

            % --- AUTO-LOAD LAST USED NOZZLE TEMPLATE ---
            templateFile = fullfile(prefdir, 'ThermalControl_TemplateData.mat');
            
            if isfile(templateFile)
                try
                    % Load the struct from the hidden file
                    loadedData = load(templateFile);
                    
                    % Assign the data back to the app properties
                    app.NozzleTemplate       = loadedData.NozzleTemplate;
                    app.TemplateRect         = loadedData.TemplateRect;
                    app.NozzleTemplateStack  = loadedData.NozzleTemplateStack;
                    app.NozzleTemplateScales = loadedData.NozzleTemplateScales;
                    app.TipCoordinates       = loadedData.TipCoordinates;
                    
                    disp('Successfully auto-loaded previous Nozzle Template Pyramid.');
                catch ME
                    disp(['Failed to auto-load previous Template. Reason: ', ME.message]);
                end
            else
                disp('No previous Nozzle Template found. Please calibrate the nozzle manually.');
            end

           CVFunctions.UpdateTemplatePreview(app); %Show the saved extruder template

        end

        % Button pushed function: DiscoverDevices
        function DiscoverDevicesPushed(app, event)
            %Begin searching for cameras
            app.AvailableCameras.Items = "Starting";
            disp("Looking for devices");
            availableCameras = ToolkitFunctions.DiscoverDevices();
            app.AvailableCameras.Items = availableCameras;
        end

        % Button pushed function: StartStream
        function StartStreamButtonPushed(app, event)
            if ~isempty(app.AvailableCameras.Value)
                %Connect to the camera and start a stream if the selected value is not empty
                ToolkitFunctions.SelectDevice(app.AvailableCameras.Value);
                %Start the camera stream 
                fig = uifigure('Position',[500 500 370 170]);
                dialog = uiprogressdlg(fig,'Title','Please Wait...', 'Message','Configuring CameraStream');

                dialog.Value = 0.55;
                ToolkitFunctions.StartStream();

                dialog.Value = 0.8;
                dialog.Message = 'CameraStream configured';
                dialog.Value = 1;
                close(dialog); close(fig);

                ToolkitFunctions.StartStream();
                app.StartStreamTimer();
            else
                disp("Empty");
            end
        end

        % Button pushed function: StopStreamButton
        function StopStreamButtonPushed(app, event)
            %Delete all timers. This stops the streaming loop
            delete(timerfind);
            ToolkitFunctions.StopStream();
            %Reset the Available Cameras to empty
            %app.AvailableCameras.Items = "";
            
        end

        % Button pushed function: TrackPointTemperatureButton
        function TrackPointTemperatureButtonPushed(app, event)
            %Disable plotting of the current point temperature
            if app.trackPointTemp
                app.trackPointTemp = false;
                app.TrackPointTemperatureButton.Text = 'Track Point Temp';
                delete(app.pointLine);
                clear app.pointLine;
                drawnow limitrate;
                %(Pedro 02/04/2026)
                % Hide the box, but keep it in memory
                app.FilteredROIBox.Visible = 'off';
                app.LiveFeedROIBox.Visible = 'off';

            else 
                %Enable plotting of the current point temperature
                app.trackPointTemp = true;
                app.TrackPointTemperatureButton.Text = 'Tracking Point Temp';

                % RESET the log and record the start time (Pedro
                % 02/03/2026)
                app.currentTempArray = []; 
                app.startTime = datetime('now');

                app.pointLine = animatedline(app.TemperatureTracker, 'MaximumNumPoints', 1000, 'Color', 'blue');
            end
        end

        % Value changing function: FocusDistance
        function FocusDistanceValueChanging(app, event)
            %The Value Changing Callback allows the user 
            %to see the focus change as they are dragging the 
            %slider rather than when they let go of the mouse button
            changingValue = event.Value;
            ToolkitFunctions.AdjustFocus(changingValue);
        end

        % Button pushed function: SendNUCCommandButton
        function SendNUCCommandButtonPushed(app, event)
            %Send a command to the camera to Enable the NUC functionality
            if app.NUCCommands.Value == "Enable NUC"
                ToolkitFunctions.EnableNUC();
            end
            
            %Send a command to the camera to Disable the NUC functionality
            if app.NUCCommands.Value == "Disable NUC"
                ToolkitFunctions.DisableNUC();
            end
            
            %Send a command to the camera to Manually fire a NUC
            if app.NUCCommands.Value == "Fire NUC"
                ToolkitFunctions.FireNUC();
            end
            
        end

        % Button pushed function: TakeIS2ScreenshotButton
        function TakeIS2ScreenshotButtonPushed(app, event)
            %Sends a command to the camera to save a .IS2 image to disk at the location specified
            screenshotPath = strcat(app.ScreenshotPath.Value, '\', app.ScreenshotFileName.Value);
            ToolkitFunctions.CaptureImage(screenshotPath);
        end

        % Button pushed function: BrowseScreenshotButton
        function BrowseScreenshotButtonPushed(app, event)
            %Opens an explorer window to allow the user to select a folder to store the .IS2 image
            filePath = uigetdir();
            if exist(filePath)
                app.ScreenshotPath.Value = filePath;
            else
                app.ScreenshotPath.Value = "Error: Not a Valid Path";
            end
        end

        % Callback function
        function ApplyButtonPushed(app, event)
            %Sends a command to the camera to set the range to -4°F-176°F
            if app.SelectedRange.Value == "First Range"
                ToolkitFunctions.SetFirstRange();
            end
            %Sends a command to the camera to set the range to -4°F-2192°F
            if app.SelectedRange.Value == "Second Range"
                ToolkitFunctions.SetSecondRange();
            end
        end

        % Button pushed function: ConfigureEBTButton
        function ConfigureEBTButtonPushed(app, event)
            %Allows the user to send a command to the camera to configure the Emissivity and Transmissivity Coefficients, as well as the Background Temp
            ToolkitFunctions.SetEBT(app.EBTEmissivity.Value, app.EBTBGTemp.Value, app.EBTTempUnit.Value, app.EBTTransmission.Value);
            uialert(app.UIFigure, 'EBT Updated', 'Export Success', 'Icon', 'success');
        end

        % Button pushed function: BrowseRecordButton
        function BrowseRecordButtonPushed(app, event)
            %Opens an explorer window to allow the user to select a folder to store the .IS3 recording
            filePath = uigetdir();
            if exist(filePath)
                app.RecordPath.Value = filePath;
            else
                app.RecordPath.Value = "Error: Not a Valid Path";
            end
        end

        % Button pushed function: RecordIS3VideoButton
        function RecordIS3VideoButtonPushed(app, event)
            %Sends a command to the camera to save a recording (.IS3 File) to disk
            ToolkitFunctions.RecordMovie(app.RecordPath.Value, app.RecordFileName.Value, app.MovieLength.Value);
            movieLength = app.MovieLength.Value / 1000.0;
            
            %The following timer is used to provide feedback to the user that the recording has completed
            recordingTimer = timer;
            recordingTimer.ExecutionMode = 'singleShot';
            recordingTimer.Name = 'Recording Timer';
            recordingTimer.StartDelay = movieLength;
            recordingTimer.TimerFcn = {@app.TriggerCallback, app};
            start(recordingTimer);
            app.RecordIS3VideoButton.Text = 'Recording in Progress';
            
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            %First Stop the camera stream to avoid bugs
            try
                delete(timerfind);
                ToolkitFunctions.StopStream();
            catch
            end

            %Close the app and clear all the variables
            delete(app) 
            %clear;           
        end

        % Button pushed function: CSVBrowseButton
        function CSVBrowseButtonPushed(app, event)
            %Opens an explorer window to allow the user to select a folder to store the .CSV file
            filePath = uigetdir();
            if exist(filePath)
                app.CSVFilePath.Value = filePath;
            else
                app.CSVFilePath.Value = "Error: Not a Valid Path";
            end
        end

        % Button pushed function: ExportDatacsvButton
        function ExportDatacsvButtonPushed(app, event)
            %(Pedro 03/03/2026)
            % Check if the log has data
            if isempty(app.currentTempArray)
                uialert(app.UIFigure, 'No data has been logged yet!', 'Export Error');
                return;
            end

            % Convert the array to a Table for better readability in Sheets
            % currentTempArray has [Time, Temperature]
            T = table(app.currentTempArray(:,1), app.currentTempArray(:,2), app.currentTempArray(:,3), 'VariableNames', {'Time_Seconds', 'Temperature_Celsius', 'DeltaT'});

            % Open the Save Dialog
            [file, path] = uiputfile('*.csv', 'Save Tracking Data');

            % Write the file if the user didn't hit cancel
            if ischar(file)
                fullFileName = fullfile(path, file);
                writetable(T, fullFileName);
                uialert(app.UIFigure, ['Data saved successfully to: ', file], 'Export Success', 'Icon', 'success');
            else
                % User canceled the save
                disp('Export canceled by user.');
            end
            
            
            %(Pedro 02/03/2026)
            %Toggle tracking
            if app.trackPointTemp
                app.trackPointTemp = false;
                app.TrackPointTemperatureButton.Text = 'Track Point Temp';
                % We don't delete the data here, just the visual line
                delete(app.pointLine);
                drawnow limitrate;
            else 
                app.trackPointTemp = true;
                app.TrackPointTemperatureButton.Text = 'Tracking Point Temp';
                
                % RESET the log and record the start time
                app.currentTempArray = []; 
                app.startTime = datetime('now'); 
                
                app.pointLine = animatedline(app.TemperatureTracker, 'MaximumNumPoints', 1000, 'Color', 'blue');
            end
            
        end

        % Button down function: FilteredAxes, LiveFeedAxes
        function AxesButtonDown(app, event)
            % 1. Ask the Axes exactly what data coordinate was clicked
            % CurrentPoint returns a 2x3 matrix. Row 1 is the [X, Y, Z] of the front face.
            coords = app.LiveFeedAxes.CurrentPoint;
            
            % 2. Extract X and Y and round to nearest whole pixel index
            cursorPositionX = round(coords(1, 1));
            cursorPositionY = round(coords(1, 2));
            
            % 3. Clamp the coordinates to prevent crashing if you click slightly outside the box
            % (Assuming IRImage is 480 rows by 640 columns)
            maxX = size(app.ThermalPlotHandle.CData, 2);
            maxY = size(app.ThermalPlotHandle.CData, 1);
            
            cursorPositionX = max(1, min(cursorPositionX, maxX));
            cursorPositionY = max(1, min(cursorPositionY, maxY));
            
            % 4. Output to your UI edit fields
            app.X.Value = cursorPositionX;
            app.Y.Value = cursorPositionY;
        end

        % Button pushed function: CreateTemplate
        function CreateTemplatePushed(app, event)
            % 1. Grab ONE frame from the camera and run your filter on it
            app.TempArray = ToolkitFunctions.GetData(app.TemperatureUnits.Value);
            [app.FilteredImageRaw, app.FilteredImageBlur] = CVFunctions.ThermalFilter(app.TempArray, 95, 24);
        
            % 2. Open a temporary pop-up window to draw the box
            f = figure('Name', 'Draw a box around the extruder', 'MenuBar', 'none');
            ax = axes(f);
            imagesc(ax, app.FilteredImageRaw);
            colormap(ax, 'turbo');
            axis(ax, 'image');
        
            % 3. Let the user draw the rectangle
            disp('Draw a rectangle around the nozzle and double-click inside it.');
        
            % USE TEMPORARY VARIABLES so we don't overwrite good data if the user aborts
            [tempTemplate, tempRect] = imcrop(ax);
        
            % 4. Safely close the window ONLY if the user didn't already click "X"
            if isvalid(f)
                close(f);
            end
        
            % 5. Check if the user actually captured something
            if ~isempty(tempTemplate)
                app.TipCoordinates = zeros(app.StackHeight, 2);
                
                % --- 1. SAVE UNBLURRED FOR GUI ---
                % Save original template and rect for the UI visuals
                app.NozzleTemplate = tempTemplate; 
                app.TemplateRect = tempRect;
                
                % --- 2. CREATE BLURRED BASE FOR MATH ---
                % Smear the template for normxcorr2 (Sigma = 1.5 is a solid baseline)
                blurredBaseTemplate = imgaussfilt(tempTemplate, 1.5);
                
                nScales = app.StackHeight;
        
                % Build template pyramid: 11 scales from 0.5 to 1.5
                scales = linspace(0.5, 1.5, nScales);   
                templateStack = cell(1, nScales);       % preallocate cell array
        
                for k = 1:nScales
                    s = scales(k);
                    % ---> THE SWAP: imresize now scales the BLURRED template <---
                    templateStack{k} = imresize(blurredBaseTemplate, s, 'bilinear');
                    
                    % Extract the tip of this blurred template
                    [tX, tY] = CVFunctions.ExtractTemplateTip(templateStack{k}); 
                    app.TipCoordinates(k, :) = [tX, tY]; % And save it
                end
        
                % Store pyramid in app for later use
                app.NozzleTemplateStack = templateStack; % This is now the blurred stack!
                app.NozzleTemplateScales = scales;
                
                % Save the template data to MATLAB's hidden pref dir
                % Notice how NozzleTemplate remains crisp, while the Stack is blurred
                templateData.NozzleTemplate       = app.NozzleTemplate; 
                templateData.TemplateRect         = app.TemplateRect;
                templateData.NozzleTemplateStack  = app.NozzleTemplateStack; 
                templateData.NozzleTemplateScales = app.NozzleTemplateScales;
                templateData.TipCoordinates       = app.TipCoordinates;
                
                % prefdir automatically finds the correct background folder for any PC
                savePath = fullfile(prefdir, 'ThermalControl_TemplateData.mat');
                save(savePath, '-struct', 'templateData');
        
                disp('Template successfully saved and blurred pyramid generated!');
                
                % Show the original template to the user
                CVFunctions.UpdateTemplatePreview(app);

            else
                disp('Calibration aborted. Previous template kept.');
            end
        end

        % Button pushed function: LoadMPFfileButton
        function LoadMPFfileButtonPushed(app, event)
            % Open file dialog (filter to .mpf)
            [fileName, filePath] = uigetfile({'*.mpf','MPF files (*.mpf)'; '*.*','All Files (*.*)'}, ...
                                             'Select MPF File');
            % User cancelled
            if isequal(fileName,0) || isequal(filePath,0)
                return;
            end
        
            fullFile = fullfile(filePath, fileName);
        
            % Basic format checks
            [~, ~, ext] = fileparts(fullFile);
            if ~strcmpi(ext, '.mpf')
                uialert(app.UIFigure, 'Selected file does not have .mpf extension.', 'File Error');
                return;
            end
        
            % Check file exists and is not empty
            info = dir(fullFile);
            if isempty(info) || info.bytes == 0
                uialert(app.UIFigure, 'Selected file is empty or not accessible.', 'File Error');
                return;
            end
        
            % Optional: read first few bytes to perform a simple header/magic check
            % (adjust expectedHeader to match your MPF format if available)
            try
                fid = fopen(fullFile, 'rb');
                header = fread(fid, 16, '*uint8');
                fclose(fid);
            catch
                uialert(app.UIFigure, 'Unable to read file header.', 'File Error');
                return;
            end
        
            % Example header check (customize as needed). Here we only
            % ensure we read data
            if isempty(header)
                uialert(app.UIFigure, 'File header appears invalid.', 'File Error');
                return;
            end

            try
                if exist('ToolkitFunctions', 'class') || exist('ToolkitFunctions', 'file')
                    app.MPFFilePath.Value = fullFile;

                    [~, fileNameOnly, ~] = fileparts(fullFile);             % Extract just the filename
                    app.LoadedFile.Value = fileNameOnly;                    % Display it in your UI component

                    setpref('ThermalControlApp', 'LastMPFFilePath', fullFile);  %Save the file path to MATLAB preferences

                    uialert(app.UIFigure, 'MPF file loaded successfully.', 'Success', 'Icon', 'success');
                    [app.layerLengths, app.layerFeedrates, app.layerTimes] = DataAnalysisFunctions.ParseMPFLayers(app); %Parse through the file
                    fprintf('Num of elements: L %d, F %d, T %d \n', length(app.layerLengths), length(app.layerFeedrates), length(app.layerTimes));
                    
                    %Debug print block
                    if ~isempty(app.layerLengths)
                        fprintf('Distances:  Min = %.2f, Max = %.2f mm\n', min(app.layerLengths), max(app.layerLengths));
                        fprintf('Feedrates:  Min = %.2f, Max = %.2f mm/min\n', min(app.layerFeedrates), max(app.layerFeedrates));
                        fprintf('Times:      Min = %.2f, Max = %.2f sec\n', min(app.layerTimes), max(app.layerTimes));
                    else
                        fprintf('WARNING: Arrays are empty! Check your Z-parsing logic.\n');
                    end
                end
            catch ME
                % Parsing failed — keep user informed and do not overwrite state
                msg = sprintf('Failed to load MPF file:\n%s', ME.message);
                uialert(app.UIFigure, msg, 'Load Error');
                return;
            end
        end

        % Button pushed function: StartTCButton
        function StartTCButtonPushed(app, event)
            if strcmp(app.SystemState, 'IDLE')

                % --- Transition to Active ---
                app.SystemState = 'PRINT_STARTED';

                % Update UI Button to be a "Stop" button
                app.StartTCButton.Text = 'Stop TC';
                app.StartTCButton.BackgroundColor = [0.8 0.2 0.2]; % Red

                tic; % <--- Starts the master stopwatch for the session!

            else
                % --- Transition back to Idle ---
                app.SystemState = 'IDLE';

                % Update UI Button to be a "Start" button
                app.StartTCButton.Text = 'Start TC';
                app.StartTCButton.BackgroundColor = [0.2 0.8 0.2]; % Green

                % --- STOP BUTTON: FULL MEMORY FLUSH ---
                
                % 1. Reset all counters and indexes back to zero
                app.PointsPerLayer = 0;
                app.GradAge = 0;
                app.DropIndex = 0;
                app.GradIndex = 0;
                
                % 2. Flush the heavy 2D matrices
                app.TempMatrix(:) = NaN;
                app.TimeMatrix(:) = NaN;
                app.GradTempMatrix(:) = NaN;
                app.GradTimeMatrix(:) = NaN;
                
                % 3. Flush the 1D tracking arrays
                app.PointAges(:) = 0;
                app.BirthTimes(:) = NaN;
                app.DroppedPointsX(:) = NaN;
                app.DroppedPointsY(:) = NaN;
                
                % 4. Clear the UI Visuals so ghost dots don't linger on screen
                if isvalid(app.DroppedPointsVisual)
                    app.DroppedPointsVisual.XData = NaN;
                    app.DroppedPointsVisual.YData = NaN;
                end
                
                % Clear the diagnostic decay plot 
                cla(app.TemperatureTracker); 
                title(app.TemperatureTracker, 'Awaiting Data...');

                disp('System State: IDLE - Tracking Paused.');
            end
        end

        % Value changed function: RangeSwitch
        function RangeSwitchValueChanged(app, event)
            activeRange = app.RangeSwitch.Value;
            
            % Route the execution directly based on the switch state
            switch activeRange
                case 'First'
                    % Trigger your first range setup configuration
                    ToolkitFunctions.SetFirstRange(); 
                    disp('Camera setting updated: First Range applied.');
                    
                case 'Second Range'
                    % Trigger your second range setup configuration
                    ToolkitFunctions.SetSecondRange();
                    disp('Camera setting updated: Second Range applied.');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1204 724];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.Scrollable = 'on';

            % Create TemperatureTracker
            app.TemperatureTracker = uiaxes(app.UIFigure);
            title(app.TemperatureTracker, 'Temperature Tracker')
            xlabel(app.TemperatureTracker, 'X (s)')
            ylabel(app.TemperatureTracker, 'Y (℃)')
            app.TemperatureTracker.LineWidth = 3;
            app.TemperatureTracker.LineStyleOrder = {'-'};
            app.TemperatureTracker.NextPlot = 'replace';
            app.TemperatureTracker.Position = [11 368 519 225];

            % Create FocusDistancemmSliderLabel
            app.FocusDistancemmSliderLabel = uilabel(app.UIFigure);
            app.FocusDistancemmSliderLabel.HorizontalAlignment = 'right';
            app.FocusDistancemmSliderLabel.Position = [805 126 120 22];
            app.FocusDistancemmSliderLabel.Text = 'Focus Distance (mm)';

            % Create FocusDistance
            app.FocusDistance = uislider(app.UIFigure);
            app.FocusDistance.Limits = [150 3000];
            app.FocusDistance.ValueChangingFcn = createCallbackFcn(app, @FocusDistanceValueChanging, true);
            app.FocusDistance.Step = 1;
            app.FocusDistance.Position = [553 177 625 3];
            app.FocusDistance.Value = 1250;

            % Create TemperatureUnitsDropDownLabel
            app.TemperatureUnitsDropDownLabel = uilabel(app.UIFigure);
            app.TemperatureUnitsDropDownLabel.HorizontalAlignment = 'right';
            app.TemperatureUnitsDropDownLabel.Position = [174 600 104 22];
            app.TemperatureUnitsDropDownLabel.Text = 'Temperature Units';

            % Create TemperatureUnits
            app.TemperatureUnits = uidropdown(app.UIFigure);
            app.TemperatureUnits.Items = {'Celsius', 'Fahrenheit', 'Kelvin'};
            app.TemperatureUnits.Position = [289 600 100 22];
            app.TemperatureUnits.Value = 'Celsius';

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.UIFigure);
            app.TabGroup2.Position = [11 13 519 350];

            % Create ServoControlTab
            app.ServoControlTab = uitab(app.TabGroup2);
            app.ServoControlTab.Title = 'Servo Control';

            % Create ControllerSettingsPanel
            app.ControllerSettingsPanel = uipanel(app.ServoControlTab);
            app.ControllerSettingsPanel.Title = 'Controller Settings';
            app.ControllerSettingsPanel.Position = [262 10 247 302];

            % Create PrinterSpeedKnob
            app.PrinterSpeedKnob = uiknob(app.ControllerSettingsPanel, 'discrete');
            app.PrinterSpeedKnob.Items = {'0', '1', '2', '4', '6', '8', '10', '20', '30', '40', '50', '60', '70', '75', '80', '85', '90', '95', '100', '105', '110', '115', '120'};
            app.PrinterSpeedKnob.ItemsData = {'0', '1', '2', '4', '6', '8', '10', '20', '30', '40', '50', '60', '70', '75', '80', '85', '90', '95', '100', '105', '110', '115', '120'};
            app.PrinterSpeedKnob.Enable = 'off';
            app.PrinterSpeedKnob.Position = [53 57 131 131];
            app.PrinterSpeedKnob.Value = '0';

            % Create StartTCButton
            app.StartTCButton = uibutton(app.ServoControlTab, 'push');
            app.StartTCButton.ButtonPushedFcn = createCallbackFcn(app, @StartTCButtonPushed, true);
            app.StartTCButton.Position = [11 247 157 65];
            app.StartTCButton.Text = 'Start ThermalControl';

            % Create TemperatureSettingsTab
            app.TemperatureSettingsTab = uitab(app.TabGroup2);
            app.TemperatureSettingsTab.Title = 'Temperature Settings';

            % Create EBTConfigurationPanel
            app.EBTConfigurationPanel = uipanel(app.TemperatureSettingsTab);
            app.EBTConfigurationPanel.Title = ' EBT Configuration';
            app.EBTConfigurationPanel.Position = [13 15 210 218];

            % Create EmissivityEditFieldLabel_2
            app.EmissivityEditFieldLabel_2 = uilabel(app.EBTConfigurationPanel);
            app.EmissivityEditFieldLabel_2.HorizontalAlignment = 'right';
            app.EmissivityEditFieldLabel_2.Position = [25 165 59 22];
            app.EmissivityEditFieldLabel_2.Text = 'Emissivity';

            % Create EBTEmissivity
            app.EBTEmissivity = uieditfield(app.EBTConfigurationPanel, 'numeric');
            app.EBTEmissivity.Limits = [0 1];
            app.EBTEmissivity.HorizontalAlignment = 'center';
            app.EBTEmissivity.Position = [102 165 81 22];
            app.EBTEmissivity.Value = 0.95;

            % Create BGTempEditFieldLabel_2
            app.BGTempEditFieldLabel_2 = uilabel(app.EBTConfigurationPanel);
            app.BGTempEditFieldLabel_2.HorizontalAlignment = 'right';
            app.BGTempEditFieldLabel_2.Position = [31 137 56 22];
            app.BGTempEditFieldLabel_2.Text = 'BG Temp';

            % Create EBTBGTemp
            app.EBTBGTemp = uieditfield(app.EBTConfigurationPanel, 'numeric');
            app.EBTBGTemp.HorizontalAlignment = 'center';
            app.EBTBGTemp.Position = [102 137 81 22];
            app.EBTBGTemp.Value = 23;

            % Create TransmissionEditFieldLabel_2
            app.TransmissionEditFieldLabel_2 = uilabel(app.EBTConfigurationPanel);
            app.TransmissionEditFieldLabel_2.HorizontalAlignment = 'right';
            app.TransmissionEditFieldLabel_2.Position = [11 110 76 22];
            app.TransmissionEditFieldLabel_2.Text = 'Transmission';

            % Create EBTTransmission
            app.EBTTransmission = uieditfield(app.EBTConfigurationPanel, 'numeric');
            app.EBTTransmission.Limits = [0 100];
            app.EBTTransmission.HorizontalAlignment = 'center';
            app.EBTTransmission.Position = [102 110 81 22];
            app.EBTTransmission.Value = 100;

            % Create ConfigureEBTButton
            app.ConfigureEBTButton = uibutton(app.EBTConfigurationPanel, 'push');
            app.ConfigureEBTButton.ButtonPushedFcn = createCallbackFcn(app, @ConfigureEBTButtonPushed, true);
            app.ConfigureEBTButton.Position = [18 18 169 31];
            app.ConfigureEBTButton.Text = 'Configure EBT';

            % Create TemperatureUnitLabel
            app.TemperatureUnitLabel = uilabel(app.EBTConfigurationPanel);
            app.TemperatureUnitLabel.HorizontalAlignment = 'center';
            app.TemperatureUnitLabel.Position = [8 75 77 22];
            app.TemperatureUnitLabel.Text = 'Temp Unit';

            % Create EBTTempUnit
            app.EBTTempUnit = uidropdown(app.EBTConfigurationPanel);
            app.EBTTempUnit.Items = {'Celsius', 'Fahrenheit', 'Kelvin'};
            app.EBTTempUnit.Position = [91 75 96 22];
            app.EBTTempUnit.Value = 'Celsius';

            % Create SendNUCCommandButton
            app.SendNUCCommandButton = uibutton(app.TemperatureSettingsTab, 'push');
            app.SendNUCCommandButton.ButtonPushedFcn = createCallbackFcn(app, @SendNUCCommandButtonPushed, true);
            app.SendNUCCommandButton.Position = [238 15 261 28];
            app.SendNUCCommandButton.Text = 'Send NUC Command';

            % Create NonUniformityCorrectionControlLabel
            app.NonUniformityCorrectionControlLabel = uilabel(app.TemperatureSettingsTab);
            app.NonUniformityCorrectionControlLabel.HorizontalAlignment = 'right';
            app.NonUniformityCorrectionControlLabel.Position = [238 58 147 22];
            app.NonUniformityCorrectionControlLabel.Text = 'Non-Uniformity Correction ';

            % Create NUCCommands
            app.NUCCommands = uidropdown(app.TemperatureSettingsTab);
            app.NUCCommands.Items = {'Enable NUC', 'Disable NUC', 'Fire NUC'};
            app.NUCCommands.Position = [390 58 109 21];
            app.NUCCommands.Value = 'Enable NUC';

            % Create TrackPointTemperaturePanel
            app.TrackPointTemperaturePanel = uipanel(app.TemperatureSettingsTab);
            app.TrackPointTemperaturePanel.Title = 'Track Point Temperature';
            app.TrackPointTemperaturePanel.Position = [237 98 264 202];

            % Create TrackPointTemperatureButton
            app.TrackPointTemperatureButton = uibutton(app.TrackPointTemperaturePanel, 'push');
            app.TrackPointTemperatureButton.ButtonPushedFcn = createCallbackFcn(app, @TrackPointTemperatureButtonPushed, true);
            app.TrackPointTemperatureButton.Position = [18 132 224 35];
            app.TrackPointTemperatureButton.Text = 'Track Point Temperature';

            % Create ROISizeDropDownLabel
            app.ROISizeDropDownLabel = uilabel(app.TrackPointTemperaturePanel);
            app.ROISizeDropDownLabel.HorizontalAlignment = 'right';
            app.ROISizeDropDownLabel.Position = [19 27 55 22];
            app.ROISizeDropDownLabel.Text = 'ROI Size';

            % Create ROISizeDropDown
            app.ROISizeDropDown = uidropdown(app.TrackPointTemperaturePanel);
            app.ROISizeDropDown.Items = {'1', '3', '5', '7'};
            app.ROISizeDropDown.Position = [82 28 38 21];
            app.ROISizeDropDown.Value = '5';

            % Create ExportDatacsvButton
            app.ExportDatacsvButton = uibutton(app.TrackPointTemperaturePanel, 'push');
            app.ExportDatacsvButton.ButtonPushedFcn = createCallbackFcn(app, @ExportDatacsvButtonPushed, true);
            app.ExportDatacsvButton.Position = [130 17 123 41];
            app.ExportDatacsvButton.Text = 'Export Data (.csv)';

            % Create CursorTempLabel
            app.CursorTempLabel = uilabel(app.TrackPointTemperaturePanel);
            app.CursorTempLabel.HorizontalAlignment = 'center';
            app.CursorTempLabel.Position = [169 93 34 22];
            app.CursorTempLabel.Text = 'Temp';

            % Create CurrentTemp
            app.CurrentTemp = uieditfield(app.TrackPointTemperaturePanel, 'numeric');
            app.CurrentTemp.HorizontalAlignment = 'center';
            app.CurrentTemp.Position = [149 72 73 22];

            % Create XLabel_2
            app.XLabel_2 = uilabel(app.TrackPointTemperaturePanel);
            app.XLabel_2.HorizontalAlignment = 'center';
            app.XLabel_2.Position = [46 93 25 22];
            app.XLabel_2.Text = 'X';

            % Create X
            app.X = uieditfield(app.TrackPointTemperaturePanel, 'numeric');
            app.X.Limits = [0 640];
            app.X.HorizontalAlignment = 'center';
            app.X.Position = [36 72 45 22];

            % Create CursorYLabel
            app.CursorYLabel = uilabel(app.TrackPointTemperaturePanel);
            app.CursorYLabel.HorizontalAlignment = 'center';
            app.CursorYLabel.Position = [100 95 25 22];
            app.CursorYLabel.Text = 'Y';

            % Create Y
            app.Y = uieditfield(app.TrackPointTemperaturePanel, 'numeric');
            app.Y.Limits = [0 480];
            app.Y.HorizontalAlignment = 'center';
            app.Y.Position = [90 72 45 22];

            % Create RangeSwitchLabel
            app.RangeSwitchLabel = uilabel(app.TemperatureSettingsTab);
            app.RangeSwitchLabel.HorizontalAlignment = 'center';
            app.RangeSwitchLabel.Position = [94 286 40 22];
            app.RangeSwitchLabel.Text = 'Range';

            % Create RangeSwitch
            app.RangeSwitch = uiswitch(app.TemperatureSettingsTab, 'slider');
            app.RangeSwitch.Items = {'First', 'Second'};
            app.RangeSwitch.ValueChangedFcn = createCallbackFcn(app, @RangeSwitchValueChanged, true);
            app.RangeSwitch.Position = [73 247 80 36];
            app.RangeSwitch.Value = 'First';

            % Create NozzleFilteringTab
            app.NozzleFilteringTab = uitab(app.TabGroup2);
            app.NozzleFilteringTab.Title = 'Nozzle Filtering';

            % Create TemplatePreviewAxes
            app.TemplatePreviewAxes = uiaxes(app.NozzleFilteringTab);
            app.TemplatePreviewAxes.XTick = [];
            app.TemplatePreviewAxes.YTick = [];
            app.TemplatePreviewAxes.ZTick = [];
            app.TemplatePreviewAxes.Position = [4 50 235 273];

            % Create CreateTemplate
            app.CreateTemplate = uibutton(app.NozzleFilteringTab, 'push');
            app.CreateTemplate.ButtonPushedFcn = createCallbackFcn(app, @CreateTemplatePushed, true);
            app.CreateTemplate.Position = [13 10 219 28];
            app.CreateTemplate.Text = 'Create Template';

            % Create LowestFilteredTemperaturePercentileSpinnerLabel
            app.LowestFilteredTemperaturePercentileSpinnerLabel = uilabel(app.NozzleFilteringTab);
            app.LowestFilteredTemperaturePercentileSpinnerLabel.HorizontalAlignment = 'center';
            app.LowestFilteredTemperaturePercentileSpinnerLabel.Position = [248 253 164 30];
            app.LowestFilteredTemperaturePercentileSpinnerLabel.Text = {'Lowest Filtered Temperature  '; 'Percentile (%)'};

            % Create LowestFilteredTempPercentile
            app.LowestFilteredTempPercentile = uispinner(app.NozzleFilteringTab);
            app.LowestFilteredTempPercentile.Step = 0.2;
            app.LowestFilteredTempPercentile.UpperLimitInclusive = 'off';
            app.LowestFilteredTempPercentile.Limits = [0 100];
            app.LowestFilteredTempPercentile.Position = [289 227 81 22];
            app.LowestFilteredTempPercentile.Value = 95;

            % Create LayerAnalysisTab
            app.LayerAnalysisTab = uitab(app.TabGroup2);
            app.LayerAnalysisTab.Title = 'Layer Analysis';

            % Create CurrentLayerLabel
            app.CurrentLayerLabel = uilabel(app.LayerAnalysisTab);
            app.CurrentLayerLabel.HorizontalAlignment = 'right';
            app.CurrentLayerLabel.Position = [39 228 78 22];
            app.CurrentLayerLabel.Text = 'Current Layer';

            % Create LayerCounter
            app.LayerCounter = uieditfield(app.LayerAnalysisTab, 'numeric');
            app.LayerCounter.Limits = [0 Inf];
            app.LayerCounter.Position = [132 224 51 31];

            % Create LoadMPFfileButton
            app.LoadMPFfileButton = uibutton(app.LayerAnalysisTab, 'push');
            app.LoadMPFfileButton.ButtonPushedFcn = createCallbackFcn(app, @LoadMPFfileButtonPushed, true);
            app.LoadMPFfileButton.Position = [23 274 123 38];
            app.LoadMPFfileButton.Text = 'Load .mpf file';

            % Create CurrentLayerLabel_2
            app.CurrentLayerLabel_2 = uilabel(app.LayerAnalysisTab);
            app.CurrentLayerLabel_2.HorizontalAlignment = 'right';
            app.CurrentLayerLabel_2.Position = [41 179 76 22];
            app.CurrentLayerLabel_2.Text = 'Toolpath dist.';

            % Create ToolpathDist
            app.ToolpathDist = uieditfield(app.LayerAnalysisTab, 'numeric');
            app.ToolpathDist.Position = [132 175 51 31];

            % Create CurrentLayerLabel_3
            app.CurrentLayerLabel_3 = uilabel(app.LayerAnalysisTab);
            app.CurrentLayerLabel_3.HorizontalAlignment = 'right';
            app.CurrentLayerLabel_3.Position = [19 131 98 22];
            app.CurrentLayerLabel_3.Text = 'Original Feedrate';

            % Create OGFeedrate
            app.OGFeedrate = uieditfield(app.LayerAnalysisTab, 'numeric');
            app.OGFeedrate.Position = [132 127 51 31];

            % Create CurrentLayerLabel_4
            app.CurrentLayerLabel_4 = uilabel(app.LayerAnalysisTab);
            app.CurrentLayerLabel_4.HorizontalAlignment = 'right';
            app.CurrentLayerLabel_4.Position = [11 87 106 22];
            app.CurrentLayerLabel_4.Text = 'Original Layer time';

            % Create OGLayerTime
            app.OGLayerTime = uieditfield(app.LayerAnalysisTab, 'numeric');
            app.OGLayerTime.Position = [132 83 51 31];

            % Create CurrentLayerLabel_5
            app.CurrentLayerLabel_5 = uilabel(app.LayerAnalysisTab);
            app.CurrentLayerLabel_5.HorizontalAlignment = 'right';
            app.CurrentLayerLabel_5.Position = [219 127 102 22];
            app.CurrentLayerLabel_5.Text = 'Modified Feedrate';

            % Create ModFeedrate
            app.ModFeedrate = uieditfield(app.LayerAnalysisTab, 'numeric');
            app.ModFeedrate.Position = [336 123 51 31];

            % Create CurrentLayerLabel_6
            app.CurrentLayerLabel_6 = uilabel(app.LayerAnalysisTab);
            app.CurrentLayerLabel_6.HorizontalAlignment = 'right';
            app.CurrentLayerLabel_6.Position = [211 83 110 22];
            app.CurrentLayerLabel_6.Text = 'Modified Layer time';

            % Create ModLayerTime
            app.ModLayerTime = uieditfield(app.LayerAnalysisTab, 'numeric');
            app.ModLayerTime.Position = [336 79 51 31];

            % Create LoadedFileLabel
            app.LoadedFileLabel = uilabel(app.LayerAnalysisTab);
            app.LoadedFileLabel.HorizontalAlignment = 'right';
            app.LoadedFileLabel.Position = [174 285 68 22];
            app.LoadedFileLabel.Text = 'Loaded File';

            % Create LoadedFile
            app.LoadedFile = uieditfield(app.LayerAnalysisTab, 'text');
            app.LoadedFile.Position = [262 285 223 22];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.AutoResizeChildren = 'off';
            app.TabGroup.Position = [542 198 650 521];

            % Create LiveFeedTab
            app.LiveFeedTab = uitab(app.TabGroup);
            app.LiveFeedTab.AutoResizeChildren = 'off';
            app.LiveFeedTab.Title = 'LiveFeed';
            app.LiveFeedTab.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create LiveFeedAxes
            app.LiveFeedAxes = uiaxes(app.LiveFeedTab);
            app.LiveFeedAxes.XTick = [];
            app.LiveFeedAxes.YTick = [];
            app.LiveFeedAxes.ZTick = [];
            app.LiveFeedAxes.ButtonDownFcn = createCallbackFcn(app, @AxesButtonDown, true);
            app.LiveFeedAxes.Position = [1 1 648 496];

            % Create FilteredImageTab
            app.FilteredImageTab = uitab(app.TabGroup);
            app.FilteredImageTab.AutoResizeChildren = 'off';
            app.FilteredImageTab.Title = 'Filtered Image';
            app.FilteredImageTab.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create FilteredAxes
            app.FilteredAxes = uiaxes(app.FilteredImageTab);
            app.FilteredAxes.XTick = [];
            app.FilteredAxes.YTick = [];
            app.FilteredAxes.ZTick = [];
            app.FilteredAxes.ButtonDownFcn = createCallbackFcn(app, @AxesButtonDown, true);
            app.FilteredAxes.Position = [1 1 648 496];

            % Create TabGroup3
            app.TabGroup3 = uitabgroup(app.UIFigure);
            app.TabGroup3.Position = [542 14 650 100];

            % Create ScreenshotTab
            app.ScreenshotTab = uitab(app.TabGroup3);
            app.ScreenshotTab.Title = 'Screenshot';

            % Create TakeIS2ScreenshotButton
            app.TakeIS2ScreenshotButton = uibutton(app.ScreenshotTab, 'push');
            app.TakeIS2ScreenshotButton.ButtonPushedFcn = createCallbackFcn(app, @TakeIS2ScreenshotButtonPushed, true);
            app.TakeIS2ScreenshotButton.Position = [510 25 120 25];
            app.TakeIS2ScreenshotButton.Text = 'Take IS2 Screenshot';

            % Create BrowseScreenshotButton
            app.BrowseScreenshotButton = uibutton(app.ScreenshotTab, 'push');
            app.BrowseScreenshotButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseScreenshotButtonPushed, true);
            app.BrowseScreenshotButton.Position = [10 25 70 25];
            app.BrowseScreenshotButton.Text = 'Browse';

            % Create ScreenshotPathLabel
            app.ScreenshotPathLabel = uilabel(app.ScreenshotTab);
            app.ScreenshotPathLabel.HorizontalAlignment = 'right';
            app.ScreenshotPathLabel.Position = [193 45 94 25];
            app.ScreenshotPathLabel.Text = 'Screenshot Path';

            % Create ScreenshotPath
            app.ScreenshotPath = uieditfield(app.ScreenshotTab, 'text');
            app.ScreenshotPath.HorizontalAlignment = 'center';
            app.ScreenshotPath.Position = [90 25 300 25];

            % Create FileNameEditFieldLabel_3
            app.FileNameEditFieldLabel_3 = uilabel(app.ScreenshotTab);
            app.FileNameEditFieldLabel_3.HorizontalAlignment = 'right';
            app.FileNameEditFieldLabel_3.Position = [420 45 60 25];
            app.FileNameEditFieldLabel_3.Text = 'File Name';

            % Create ScreenshotFileName
            app.ScreenshotFileName = uieditfield(app.ScreenshotTab, 'text');
            app.ScreenshotFileName.HorizontalAlignment = 'center';
            app.ScreenshotFileName.Position = [400 25 100 25];
            app.ScreenshotFileName.Value = 'Screenshot';

            % Create CSVTab
            app.CSVTab = uitab(app.TabGroup3);
            app.CSVTab.Title = 'CSV';

            % Create ExporttoCSVButton
            app.ExporttoCSVButton = uibutton(app.CSVTab, 'push');
            app.ExporttoCSVButton.Position = [510 25 120 25];
            app.ExporttoCSVButton.Text = 'Export to CSV';

            % Create CSVBrowseButton
            app.CSVBrowseButton = uibutton(app.CSVTab, 'push');
            app.CSVBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @CSVBrowseButtonPushed, true);
            app.CSVBrowseButton.Position = [10 25 70 25];
            app.CSVBrowseButton.Text = 'Browse';

            % Create CSVFilePathLabel
            app.CSVFilePathLabel = uilabel(app.CSVTab);
            app.CSVFilePathLabel.HorizontalAlignment = 'right';
            app.CSVFilePathLabel.Position = [200 45 80 25];
            app.CSVFilePathLabel.Text = 'CSV File Path';

            % Create CSVFilePath
            app.CSVFilePath = uieditfield(app.CSVTab, 'text');
            app.CSVFilePath.HorizontalAlignment = 'center';
            app.CSVFilePath.Position = [90 25 300 25];

            % Create CSVFileNameLabel
            app.CSVFileNameLabel = uilabel(app.CSVTab);
            app.CSVFileNameLabel.HorizontalAlignment = 'center';
            app.CSVFileNameLabel.Position = [406 45 88 25];
            app.CSVFileNameLabel.Text = 'CSV File Name';

            % Create CSVFileName
            app.CSVFileName = uieditfield(app.CSVTab, 'text');
            app.CSVFileName.HorizontalAlignment = 'center';
            app.CSVFileName.Position = [400 25 100 25];
            app.CSVFileName.Value = 'TempData';

            % Create IS3VideoTab
            app.IS3VideoTab = uitab(app.TabGroup3);
            app.IS3VideoTab.Title = 'IS3 Video';

            % Create RecordIS3VideoButton
            app.RecordIS3VideoButton = uibutton(app.IS3VideoTab, 'push');
            app.RecordIS3VideoButton.ButtonPushedFcn = createCallbackFcn(app, @RecordIS3VideoButtonPushed, true);
            app.RecordIS3VideoButton.Position = [510 25 120 25];
            app.RecordIS3VideoButton.Text = 'Record IS3 Video';

            % Create BrowseRecordButton
            app.BrowseRecordButton = uibutton(app.IS3VideoTab, 'push');
            app.BrowseRecordButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseRecordButtonPushed, true);
            app.BrowseRecordButton.Position = [10 25 70 25];
            app.BrowseRecordButton.Text = 'Browse';

            % Create RecordingPathLabel
            app.RecordingPathLabel = uilabel(app.IS3VideoTab);
            app.RecordingPathLabel.HorizontalAlignment = 'right';
            app.RecordingPathLabel.Position = [171 45 88 25];
            app.RecordingPathLabel.Text = 'Recording Path';

            % Create RecordPath
            app.RecordPath = uieditfield(app.IS3VideoTab, 'text');
            app.RecordPath.HorizontalAlignment = 'center';
            app.RecordPath.Position = [90 25 250 25];

            % Create FileNameEditFieldLabel_4
            app.FileNameEditFieldLabel_4 = uilabel(app.IS3VideoTab);
            app.FileNameEditFieldLabel_4.HorizontalAlignment = 'right';
            app.FileNameEditFieldLabel_4.Position = [420 45 60 25];
            app.FileNameEditFieldLabel_4.Text = 'File Name';

            % Create RecordFileName
            app.RecordFileName = uieditfield(app.IS3VideoTab, 'text');
            app.RecordFileName.HorizontalAlignment = 'center';
            app.RecordFileName.Position = [400 25 100 25];
            app.RecordFileName.Value = 'Recording';

            % Create LengthmSEditFieldLabel
            app.LengthmSEditFieldLabel = uilabel(app.IS3VideoTab);
            app.LengthmSEditFieldLabel.HorizontalAlignment = 'right';
            app.LengthmSEditFieldLabel.Position = [334 45 72 25];
            app.LengthmSEditFieldLabel.Text = 'Length (mS)';

            % Create MovieLength
            app.MovieLength = uieditfield(app.IS3VideoTab, 'numeric');
            app.MovieLength.Limits = [0 60000];
            app.MovieLength.ValueDisplayFormat = '%11.5g';
            app.MovieLength.HorizontalAlignment = 'center';
            app.MovieLength.Position = [350 25 40 25];

            % Create DiscoverDevices
            app.DiscoverDevices = uibutton(app.UIFigure, 'push');
            app.DiscoverDevices.ButtonPushedFcn = createCallbackFcn(app, @DiscoverDevicesPushed, true);
            app.DiscoverDevices.Position = [42 686 205 28];
            app.DiscoverDevices.Text = 'Discover Devices';

            % Create StartStream
            app.StartStream = uibutton(app.UIFigure, 'push');
            app.StartStream.ButtonPushedFcn = createCallbackFcn(app, @StartStreamButtonPushed, true);
            app.StartStream.BackgroundColor = [0.698 0.9686 0.5137];
            app.StartStream.Position = [307 645 102 50];
            app.StartStream.Text = 'Start Stream';

            % Create StopStreamButton
            app.StopStreamButton = uibutton(app.UIFigure, 'push');
            app.StopStreamButton.ButtonPushedFcn = createCallbackFcn(app, @StopStreamButtonPushed, true);
            app.StopStreamButton.BackgroundColor = [0.9412 0.6 0.6];
            app.StopStreamButton.Position = [411 645 101 50];
            app.StopStreamButton.Text = 'Stop Stream';

            % Create AvailableCamerasLabel
            app.AvailableCamerasLabel = uilabel(app.UIFigure);
            app.AvailableCamerasLabel.HorizontalAlignment = 'right';
            app.AvailableCamerasLabel.Position = [94 663 106 22];
            app.AvailableCamerasLabel.Text = 'Available Cameras';

            % Create AvailableCameras
            app.AvailableCameras = uilistbox(app.UIFigure);
            app.AvailableCameras.Items = {};
            app.AvailableCameras.Tooltip = {'Sobel --good (standard)'; 'Canny --noisy'; 'Prewitt --nice'};
            app.AvailableCameras.Position = [45 636 205 28];
            app.AvailableCameras.Value = {};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ThermalControlDev_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end