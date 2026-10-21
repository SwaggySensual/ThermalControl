classdef DataAnalysisFunctions
    methods (Static)       
        function [layerLengths, layerFeedrates, layerTimes] = ParseMPFLayers(app)
            % 1. Access the file path
            filename = app.MPFFilePath.Value;
            
            if isempty(filename) || ~isfile(filename)
                uialert(app.UIFigure, 'Invalid file path.', 'Error', 'Icon', 'error');
                return;
            end
        
            lines = readlines(filename);
            
            % --- 2. Initialize Arrays & Tracking ---
            layerLengths = [];   
            layerFeedrates = []; 
            layerTimes = [];     
            
            curDist = 0;
            curTimeMin = 0;
            
            currentX = 0; currentY = 0; currentZ = 0;
            currentF = 1000; % Default
            
            firstLayerFound = false;
            firstMoveInFile = true;
        
            % --- 3. Parse File ---
            for i = 1:length(lines)
                line = strtrim(lines(i));
                if line == "", continue; end
                
                % A. LAYER TRIGGER CHECK
                % We check this BEFORE skipping comments, because the trigger IS a comment.
                if startsWith(line, ';LAYER:')
                    % If we already have data from a previous layer, save it now
                    if firstLayerFound && (curDist > 0 || curTimeMin > 0)
                        layerLengths(end+1)   = curDist;
                        layerTimes(end+1)     = curTimeMin * 60;
                        layerFeedrates(end+1) = currentF;
                        
                        % Reset accumulators for the next layer
                        curDist = 0;
                        curTimeMin = 0;
                    end
                    firstLayerFound = true; 
                    continue; % Move to next line
                end
                
                % B. Skip other comments
                if startsWith(line, ';'), continue; end
                
                % C. Update Feedrate (F)
                fMatch = regexp(line, 'F([\d.]+)', 'tokens');
                if ~isempty(fMatch)
                    currentF = str2double(fMatch{1}{1});
                end
                
                % D. Process G1 Moves
                if startsWith(line, 'G1')
                    xMatch = regexp(line, 'X([-\d.]+)', 'tokens');
                    yMatch = regexp(line, 'Y([-\d.]+)', 'tokens');
                    zMatch = regexp(line, 'Z([-\d.]+)', 'tokens');
                    
                    newX = currentX; newY = currentY; newZ = currentZ;
                    moved = false;
                    
                    if ~isempty(xMatch), newX = str2double(xMatch{1}{1}); moved = true; end
                    if ~isempty(yMatch), newY = str2double(yMatch{1}{1}); moved = true; end
                    if ~isempty(zMatch), newZ = str2double(zMatch{1}{1}); moved = true; end
                    
                    if moved
                        if firstMoveInFile
                            % Just establish the starting point for the very first move
                            currentX = newX; currentY = newY; currentZ = newZ;
                            firstMoveInFile = false;
                        else
                            % 3D Distance Formula (Crucial for Spiral/Vase mode)
                            dist = sqrt((newX - currentX)^2 + (newY - currentY)^2 + (newZ - currentZ)^2);
                            
                            % Accumulate data for the CURRENT layer
                            curDist = curDist + dist;
                            if currentF > 0
                                curTimeMin = curTimeMin + (dist / currentF);
                            end
                            
                            % Update state
                            currentX = newX; currentY = newY; currentZ = newZ;
                        end
                    end
                end
            end
            
            % --- 4. Capture the Final Layer ---
            if firstLayerFound && (curDist > 0 || curTimeMin > 0)
                layerLengths(end+1)   = curDist;
                layerTimes(end+1)     = curTimeMin * 60;
                layerFeedrates(end+1) = currentF;
            end
        end

        function updateLayerDataDisplay(app)
            % 1. Get the current layer index from the edit field
            n = app.LayerCounter.Value;
            
            % 2. Safety Check: Make sure the index exists in our arrays
            if n > 0 && n <= length(app.layerLengths)
                % 3. Update the UI fields
                app.ToolpathDist.Value = app.layerLengths(n);
                app.OGFeedrate.Value   = app.layerFeedrates(n);
                app.OGLayerTime.Value  = app.layerTimes(n);
            else
                % If layer doesn't exist, reset fields to 0 or show a warning
                app.ToolpathDist.Value = 0;
                app.OGFeedrate.Value   = 0;
                app.OGLayerTime.Value  = 0;
            end
        end


        function CalculateDynamicFeedrate(app, validTempMatrix, validTimeMatrix)
            disp('LAYER SUMMARY');
            % Save a pristine copy to track NaN locations later
            originalTempMatrix = validTempMatrix;

            % --- Clean Data & Calculate AUC ---
            numPoints = size(validTempMatrix, 1);
            aucValues = zeros(numPoints, 1);

            n = app.GradAge;
        
            for i = 1:numPoints
                tempRow = validTempMatrix(i, 1:n); %Only clean data from 1 to n
                timeRow = validTimeMatrix(i, 1:n);
        
                % Fill NaNs using linear interpolation 
                % (Fallback to 'nearest' to handle any trailing NaNs at the very end)
                tempClean = fillmissing(tempRow, 'linear');
                tempClean = fillmissing(tempClean, 'nearest');
                timeClean = timeRow;
        
                % 3. --- AUTOMATED REHEAT SPIKE ELIMINATION ---
                % Find the lowest temperature point (the true end of the cooling curve)
                [~, minIdx] = min(tempClean);
                
                % Truncate both vectors to throw away any points after the minimum
                tempClean = tempClean(1:minIdx);
                timeClean = timeClean(1:minIdx);
        
                % 4. Overwrite master matrices with pristine data 
                % Clear the active segment with NaNs first to clear old spikes
                validTempMatrix(i, 1:n) = NaN;
                validTimeMatrix(i, 1:n) = NaN;
                
                % Paste the true, sanitized cooling curve back in
                validTempMatrix(i, 1:length(tempClean)) = tempClean;
                validTimeMatrix(i, 1:length(timeClean)) = timeClean;

                % --- THE ABSOLUTE VELOCITY & SIZE GUARDRAIL ---
                % Check if either vector is empty, a single scalar, contains NaNs, 
                % or doesn't have at least two points to form a geometric area.
                if isempty(tempClean) || isempty(timeClean) || ...
                   isscalar(tempClean) || isscalar(timeClean) || ...
                   length(tempClean) < 5 || any(isnan(tempClean))
                
                    aucValues(i) = 0; % Assign safe fallback area
                    continue;        % Force-skip this corrupted point and move to the next one safely
                end
                % ------------------------------------------------
        
                % 5. Calculate Area Under the Curve (AUC) on the pure cooling window
                aucValues(i) = trapz(timeClean, tempClean);
            end
        
            % --- Identify Leading Point and Fit Curve ---
            % The leading point is the one with the highest overall heat retention
            [~, maxIdx] = max(aucValues);
            leadingTemp = validTempMatrix(maxIdx, 1:n);
            leadingTime = validTimeMatrix(maxIdx, 1:n);

            actualPointsLen = sum(~isnan(leadingTemp));
            leadingTemp = leadingTemp(1:actualPointsLen);
            leadingTime = leadingTime(1:actualPointsLen);

            % 1. Initialize the fit options specifically for the library 'exp2' model
            opts = fitoptions('exp2');
            
            % 2. Set strict bounds to keep the physics realistic
            % Amplitudes (a, c) must be positive -> Lower bound = 0
            % Decay rates (b, d) MUST be negative constants -> Upper bound = 0
            opts.Lower = [0, -Inf, 0, -Inf];
            opts.Upper = [Inf, 0, Inf, 0];
            
            % 3. Provide a sensible starting guess so it converges fast and doesn't get stuck
            % Format: [a, b, c, d]
            opts.StartPoint = [50, -0.05, 100, -0.005];
        
            % Create the Bi-Exponential Fit (Requires Curve Fitting Toolbox)
            % Wrapped in try-catch so bad sensor data doesn't crash the print
            warning('off', 'curvefit:fit:equationBadlyConditioned');
            try
                fitCurve = fit(leadingTime', leadingTemp', 'exp2', opts);
            catch
                disp('WARNING: Bi-exponential fit failed. Skipping feedrate adjustment.');
                return;
            end
            warning('on', 'curvefit:fit:equationBadlyConditioned');

            % =========================================================
            % --- DIAGNOSTIC PLOT: Visualizing the Fit ---
            % =========================================================
            try
                % 1. Clear the old plot
                cla(app.TemperatureTracker);
                hold(app.TemperatureTracker, 'on');

                % 2. --- THE SEPARATION LOGIC ---
                % Check our snapshot to see which indices were NaNs before cleaning
                leadingOriginal = originalTempMatrix(maxIdx, 1:actualPointsLen);
                isInterpolated  = isnan(leadingOriginal);
                
                % Slice into real vs estimated components
                realTime = leadingTime(~isInterpolated);
                realTemp = leadingTemp(~isInterpolated);
                
                interpTime = leadingTime(isInterpolated);
                interpTemp = leadingTemp(isInterpolated);
                
                % 2a. Plot empirical hardware data (Blue Dots)
                if ~isempty(realTime)
                    plot(app.TemperatureTracker, realTime, realTemp, 'ob', ...
                        'MarkerFaceColor', 'b', 'DisplayName', 'Empirical Data');
                end
                
                % 2b. Plot fillmissing mathematical estimations (Light Purple Dots)
                if ~isempty(interpTime)
                    plot(app.TemperatureTracker, interpTime, interpTemp, 'o', ...
                        'MarkerEdgeColor', [0.5, 0.3, 0.7], ...   % Darker purple outline
                        'MarkerFaceColor', [0.75, 0.55, 0.9], ... % Light purple body
                        'DisplayName', 'Interpolated Estimation');
                end

                % 3. Plot the Bi-exponential Fit (Red Line)
                % Generate a smooth extended time vector to see where the curve is going
                maxExtrapTime = max(leadingTime);
                smoothTime = linspace(0, maxExtrapTime*1.5, 200);
                smoothFit = fitCurve(smoothTime);
                plot(app.TemperatureTracker, smoothTime, smoothFit, '-r', ...
                    'LineWidth', 1, 'DisplayName', 'Bi-Exp Fit');

                % 4. Plot the Target Temperature (Black Dashed Line)
                targetT = app.TargetTemp;
                plot(app.TemperatureTracker, [0, maxExtrapTime*1.5], [targetT, targetT], '--k', ...
                    'LineWidth', 1, 'DisplayName', 'Target Temp');

                % 5. Add UI Polish
                xlim(app.TemperatureTracker, [0, maxExtrapTime*1.5]);
                ylim(app.TemperatureTracker, [20, 215]);
                xlabel(app.TemperatureTracker, 'Time (s)');
                ylabel(app.TemperatureTracker, 'Temperature');
                legend(app.TemperatureTracker, 'Location', 'southwest');
                grid(app.TemperatureTracker, 'on');
                hold(app.TemperatureTracker, 'off');
            catch
                disp('WARNING: Diagnostic plot failed. Check axes name.');
            end
        
            % --- Extract Ideal Layer Time ---
            % We need to find the exact time 't' where fitCurve(t) == TargetTemp.
            targetTemp = app.TargetTemp;
            
            % Define the zero-finding mathematical function
            rootFunc = @(t) fitCurve(t) - targetTemp;
            
            % Estimate a starting search point (use the last recorded time)
            initialGuess = leadingTime(1);
            %initialGuess = 33;
            %initialGuess = [10, 200];
            
            try
                idealLayerTime = fzero(rootFunc, initialGuess);
                fprintf('Ideal Layer Time = %.2fs', idealLayerTime); %Troubleshoot display
                
                % Safety Bounds: If the curve never hits the target, fzero might return nonsense
                if idealLayerTime <= 0
                    disp('WARNING: Extrapolated time unrealistic. Bounding to safe limits.');
                    idealLayerTime = max(initialGuess, app.OGLayerTime.Value);
                end
            catch
                disp('WARNING: Target Temp intersection not found. Defaulting to original time.');
                idealLayerTime = app.OGLayerTime.Value;
            end
        
            % --- Compare Times & Calculate Scaling ---
            origLayerTime = app.OGLayerTime.Value;
            origFeedrate  = app.OGFeedrate.Value;
        
            if origLayerTime <= 0 || origFeedrate <= 0
                disp('ERROR: Invalid G-Code parameters in UI. Aborting adjustment.');
                return;
            end
        
            % Inverse scaling: If Ideal Time is larger, multiplier becomes < 1 (Slower Print)
            speedMultiplier = origLayerTime / idealLayerTime;
        
            % --- Ideal Feedrate and Discrete Snapping ---
            % Calculate exact percentage of original speed needed
            idealPercent = speedMultiplier * 100;
            idealFeedrate = origFeedrate*speedMultiplier;
            %disp(idealFeedrate);

            %minFeedrate = (app.minRPM * app.materialNumber) / (app.layerWidth * app.layerHeight);
            minFeedrate = (5 * 1958) / (6 * 2);
            disp(minFeedrate);

            if idealFeedrate < minFeedrate
                idealFeedrate = minFeedrate;

                % Recalculate the ideal percentage based on the new constrained feedrate
                idealPercent = (idealFeedrate / origFeedrate) * 100;

                % Log the intervention to the command window for diagnostics
                disp('WARNING: Ideal feedrate constrained by minimum extruder RPM limits.');
            end
        
            % The allowed machine states
            allowedSteps = [0, 1, 2, 4, 6, 8, 10, 20, 30, 40, 50, 60, 70, 75, ...
                            80, 85, 90, 95, 100, 105, 110, 115, 120];
        
            % Find the absolute closest discrete step
            [~, closestIdx] = min(abs(allowedSteps - idealPercent));
            finalPercent = allowedSteps(closestIdx);
            %disp(finalPercent);
        
            % Calculate the actual commanded feedrate for display
            finalFeedrate = origFeedrate * (finalPercent / 100);
            app.ModFeedrate.Value = finalFeedrate;
            app.ModLayerTime.Value = (app.ToolpathDist.Value / finalFeedrate) * 60;
            %disp(finalFeedrate);


            % --- Diagnostic Print ---
            disp('=========================================');
            disp('--- DYNAMIC FEEDRATE ACTUATION ---');
            %fprintf('Leading Point AUC : %.2f\n', aucValues(maxIdx));
            fprintf('Original G-Code   : Time = %.2fs | Speed = F%.0f\n', origLayerTime, origFeedrate);
            fprintf('Thermal Target    : Time = %.2fs | Speed = F%.0f | Factor = %.1f%%\n', idealLayerTime, idealFeedrate, idealPercent);
            fprintf('-> Snapped Knob   : %d%%\n', finalPercent);
            fprintf('-> Commanded Speed: F%.0f\n', finalFeedrate);
            disp('=========================================');

            % --- Update GUI ---
            app.PrinterSpeedKnob.Value = num2str(finalPercent); %num2str maybe helps
        end

        function updateFPSTracker(app, ax, isLiveFeed)
            % =========================================================
            % --- LIVE FPS DIAGNOSTIC TRACKER OVERLAY ---
            % =========================================================
            
            % 1. Calculate elapsed time since the last frame call
            if isempty(app.LastFrameTime)
                app.LastFrameTime = tic;
                return; % Initialize on the first frame and wait for the second frame
            end
            
            dt = toc(app.LastFrameTime);
            app.LastFrameTime = tic; % Instantly restart clock for the next frame
            
            % Compute frame rate (guard against instantaneous execution division-by-zero)
            if dt > 0
                fps = 1 / dt;
            else
                fps = 0;
            end
            
            % 2. Select the persistent text handle based on the active display axis
            if isLiveFeed
                hText = app.LiveFPSHandle;
            else
                hText = app.FilteredFPSHandle;
            end
            
            % 3. Format the display string
            fpsString = sprintf('FPS: %.1f', fps);
            
            % 4. Dynamically capture the spatial limits of the current axis
            xLim = get(ax, 'XLim');
            yLim = get(ax, 'YLim');
            
            % Position text exactly 95% across the X-axis and 5% down the Y-axis (top right)
            xPos = xLim(1) + 0.95 * (xLim(2) - xLim(1));
            yPos = yLim(1) + 0.05 * (yLim(2) - yLim(1));
            
            % 5. Render or update the graphic text box
            if isempty(hText) || ~isvalid(hText)
                % Object doesn't exist yet: construct a new text object on the axis
                hText = text(ax, xPos, yPos, fpsString, ...
                    'Color', 'w', ...
                    'FontSize', 11, ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'top', ...
                    'Layer', 'front'); % Ensures it draws over imagesc
                    
                % Save the handle back to the app property so we can recycle it
                if isLiveFeed
                    app.LiveFPSHandle = hText;
                else
                    app.FilteredFPSHandle = hText;
                end
            else
                % Optimization: Simply update the string and position properties 
                % instead of wasting CPU rebuilding the graphics object
                set(hText, 'Position', [xPos, yPos, 0], 'String', fpsString);
            end
            
            % 6. DYNAMIC PERFORMANCE CRITERIA WARNER
            % If the loop falls behind your 10 FPS threshold, turn the overlay box red
            if fps < 10
                set(hText, 'BackgroundColor', [0.8 0 0 0.7]); % Translucent warning red
            else
                set(hText, 'BackgroundColor', [0 0 0 0.5]);   % Standard clean translucent black
            end
        end
    end
end
