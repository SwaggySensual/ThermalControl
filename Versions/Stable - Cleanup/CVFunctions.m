classdef CVFunctions

    methods(Static)

        function [FilteredImage, FilteredImageBlur] = ThermalFilter(TempArray, filter_value)
            % PART 1: THERMAL FILTERING
            extruder_threshold = prctile(TempArray(:), filter_value); % Calculate threshold
            extruder_mask = (TempArray >= extruder_threshold);
            
            % Filter out all blobs except the biggest one
            binaryMask = bwareafilt(extruder_mask, 1);
            
            % Clean up the mask, remove holes and ragged edges
            binaryMask = imfill(logical(binaryMask), 'holes');
            
            % --- THE FIX ---
            % 1. Copy the raw temperatures over
            FilteredImage = double(TempArray); 
            
            % 2. Target the background (where mask is 0) and set to Room Temp
            FilteredImage(~binaryMask) = 0; 
            
            % --- THE BLUR ---
            % 3. Smear the edge between the hot nozzle and the 25°C background
            % A sigma of 1.5 is a highly stable starting point for thermal gradients
            FilteredImageBlur = imgaussfilt(FilteredImage, 1.5); 
        end

        function [tipX, tipY] = ExtractTemplateTip(tempTemplate)
            % EXTRACTTEMPLATETIP Finds the geometric lowest point of the nozzle template
            
            % 1. Normalize the template to a 0-1 scale for computer vision functions
            min_temp = min(tempTemplate(:));
            max_temp = max(tempTemplate(:));
        
            % Safety: Prevent division by zero if the user crops a completely flat background
            if max_temp == min_temp
                tipX = round(size(tempTemplate, 2) / 2);
                tipY = size(tempTemplate, 1);
                return;
            end
        
            grayImage = (tempTemplate - min_temp) / (max_temp - min_temp);
        
            % 2. Create a Binary Mask using Otsu's Method
            % This automatically calculates the best threshold to separate the hot nozzle
            % from any cooler background captured in the crop box.
            level = graythresh(grayImage);
            binaryMask = imbinarize(grayImage, level);
        
            % 3. Find all pixels belonging to the hot nozzle body
            [rows, cols] = find(binaryMask);
        
            if ~isempty(rows)
                % 4. Find the physical tip
                % In MATLAB, Row 1 is the top of the image. The lowest point is the MAX Row.
                tipY = max(rows);
        
                % 5. Center the X coordinate
                % If the tip is slightly flat (multiple pixels on the bottom row), 
                % we take the average X position to find the true center.
                tipX = round(mean(cols(rows == tipY)));
            else
                % Fallback if the mask somehow fails: assume bottom-center of the crop box
                tipX = round(size(tempTemplate, 2) / 2);
                tipY = size(tempTemplate, 1);
            end
        end

        function LayerTripwire(app, InputImage)
            % 1. Setup and position the visual line
            [height, width] = size(InputImage);
            x_center = round(width / 2);

            % Snap the visual line to the center if it hasn't been set yet
            if strcmp(app.TripwireVisual.Visible, 'off')
                app.TripwireVisual.XData = [x_center, x_center];
                app.TripwireVisual.YData = [1, height];
                app.TripwireVisual.Visible = 'on';
            end

            % 2. Extract the thermal data for that specific column
            tripwire_column = InputImage(:, x_center);
            current_tripwire_max = max(tripwire_column);

            % 3. The State Machine Logic
            if current_tripwire_max > app.TripwireThreshold
                % NOZZLE DETECTED
                if ~app.IsNozzleInTripwire
                    app.IsNozzleInTripwire = true;
                    % Turn the tripwire RED for visual feedback!
                    app.TripwireVisual.Color = [1, 0, 0];
                    %disp('Nozzle entered tripwire.');
                    % Count the pass
                    app.TripwirePassCount = app.TripwirePassCount + 1;
                    app.CurrentLayer = floor(app.TripwirePassCount / 2) + 1;
                    % Update the counter
                    app.LayerCounter.Value = app.CurrentLayer;
                    %fprintf('Current Layer: %d\n', app.CurrentLayer);

                    DataAnalysisFunctions.updateLayerDataDisplay(app); %Update the field texts in the GUI
                end
            else
                % NOZZLE EXITED
                if app.IsNozzleInTripwire
                    app.IsNozzleInTripwire = false;
                    % Turn the tripwire back to GREEN
                    app.TripwireVisual.Color = [50/255, 205/255, 50/255];
                end
            end
        end

        function FilteredImage = TemplateMatching(app, FilteredImage)
            % --- 1. EARLY EXIT & SETUP ---
            if isempty(app.NozzleTemplateStack)
                return;
            end
            [imgHeight, imgWidth] = size(FilteredImage);
        
            % --- 2. SCALE LOCKING (Hill-Climbing Search) ---
            if isempty(app.CurrentScaleIdx)
                app.CurrentScaleIdx = ceil(length(app.NozzleTemplateStack) / 2);
            end
            
            % Define the search window (clamp strictly to boundaries)
            searchStart = max(1, app.CurrentScaleIdx - 1);
            searchEnd   = min(length(app.NozzleTemplateStack), app.CurrentScaleIdx + 1);
            
            global_max_score = -1;
            best_template_idx = app.CurrentScaleIdx; 
            best_template = []; 
            
            % Loop ONLY the adjacent scales, searching the ENTIRE image
            for k = searchStart:searchEnd
                current_template = app.NozzleTemplateStack{k};
                correlation_map = normxcorr2(current_template, FilteredImage);
                [local_max_score, local_max_idx] = max(correlation_map(:));
                
                if local_max_score > global_max_score
                    global_max_score = local_max_score;
                    [best_ypeak, best_xpeak] = ind2sub(size(correlation_map), local_max_idx);
                    best_template_idx = k;
                    best_template = current_template;
                end
            end
            
            app.CurrentScaleIdx = best_template_idx; % Lock in winning scale
        
            % =========================================================
            % --- 3. CONFIDENCE CHECK (Prevent False Positives) ---
            % =========================================================
            if global_max_score < 0.30
                app.ExtruderTip.XData = NaN;
                app.ExtruderTip.YData = NaN;
                app.ExtruderTip.ZData = NaN;
                
                disp('Lost extruder tracking. Re-acquiring next frame.');
                return;
            end
        
            % =========================================================
            % --- 4. GLOBAL MAPPING ---
            % =========================================================
            [tH, tW] = size(best_template);
            r_end   = best_ypeak;
            c_end   = best_xpeak;
            r_start = best_ypeak - tH + 1;
            c_start = best_xpeak - tW + 1;
            
            % Clamp strictly to boundaries for extraction
            r_start_valid = max(1, r_start);
            r_end_valid   = min(imgHeight, r_end);
            c_start_valid = max(1, c_start);
            c_end_valid   = min(imgWidth, c_end);
            
            % =========================================================
            % --- 5. EXTRUDER TIP EXTRACTION ---
            % =========================================================
            scaled_tipX = app.TipCoordinates(best_template_idx, 1);
            scaled_tipY = app.TipCoordinates(best_template_idx, 2);
            
            app.ExtruderTip.XData = max(1, min(imgWidth, c_start + scaled_tipX - 1));
            app.ExtruderTip.YData = max(1, min(imgHeight, r_start + scaled_tipY - 1));
            app.ExtruderTip.ZData = 2; % Force render on top
        
            % =========================================================
            % --- 6. EXTRUDER CARVING & VISUALIZATION ---
            % =========================================================
            templateMask = imdilate(best_template > 25, strel('disk', 4)); 
            
            % Trim mask if template is partially off-screen
            mask_r_start = 1 + (r_start_valid - r_start);
            mask_r_end   = tH - (r_end - r_end_valid);
            mask_c_start = 1 + (c_start_valid - c_start);
            mask_c_end   = tW - (c_end - c_end_valid);
            
            validTemplateMask = templateMask(mask_r_start:mask_r_end, mask_c_start:mask_c_end);
            
            % ---> NEW: Extract the 1-pixel outline of the mask <---
            outlineMask = bwperim(validTemplateMask);
            
            % Carve the nozzle out of the live image to prevent self-tracking
            liveROI = FilteredImage(r_start_valid:r_end_valid, c_start_valid:c_end_valid);
            
            % 1. Hollow out the nozzle body (Set to 0 / Cold)
            liveROI(validTemplateMask) = 0; 
            
            % 2. Draw the outline (Set to your max axis temperature, e.g., 250)
            liveROI(outlineMask) = 250; 
            
            % Paste it back into the main image
            FilteredImage(r_start_valid:r_end_valid, c_start_valid:c_end_valid) = liveROI;
        end

        function TrackingPoints(app, FilteredImageRaw, FilteredImageCarved)
            MAX_BUFFER = app.MatrixSize;

            % Get the absolute elapsed time in seconds as a simple number
            currentTime = toc;
        
            % --- SAFETY GATE ---
            if isempty(app.ExtruderTip.XData) || isnan(app.ExtruderTip.XData(1))
                disp('No extruder tip data');
                return; 
            end
        
            % --- DROP A NEW POINT ---
            app.PointsPerLayer = app.PointsPerLayer + 1;
            app.DropIndex = app.DropIndex + 1;

            if app.DropIndex > MAX_BUFFER
                app.DropIndex = 1;
            end
            
            % --- Thermal Peak Snapping ---
            rawX = round(app.ExtruderTip.XData(1));
            rawY = round(app.ExtruderTip.YData(1));
            [maxRows, maxCols] = size(FilteredImageRaw);
            
            searchRadius = 11; 
            colStart = max(1, rawX - searchRadius);
            colEnd   = min(maxCols, rawX + searchRadius);
            rowStart = max(1, rawY - searchRadius);
            rowEnd   = min(maxRows, rawY + searchRadius);
            
            neighborhood = FilteredImageRaw(rowStart:rowEnd, colStart:colEnd);
            [~, maxLinearIndex] = max(neighborhood(:));
            [localY, localX] = ind2sub(size(neighborhood), maxLinearIndex);
            
            app.DroppedPointsX(app.DropIndex) = colStart + localX - 1;
            app.DroppedPointsY(app.DropIndex) = rowStart + localY - 1;
            
            % --- Initialize memory for the new point ---
            app.TempMatrix(app.DropIndex, :) = NaN; 
            app.TimeMatrix(app.DropIndex, :) = NaN; % <--- Wipe old time memory
            app.PointAges(app.DropIndex) = 1;        
            app.BirthTimes(app.DropIndex) = currentTime; % <--- Stamp birth time
            
            % --- Update Visuals ---
            activeIdx = find(app.PointAges > 0);
            x_vals = app.DroppedPointsX(activeIdx);
            y_vals = app.DroppedPointsY(activeIdx);
            
            app.DroppedPointsVisual.XData = x_vals(:)';
            app.DroppedPointsVisual.YData = y_vals(:)';

            uistack(app.DroppedPointsVisual, 'top'); %Force the points to the absolute front layer

        
            % --- AGE AND GRADUATE ---
            for i = 1:MAX_BUFFER
                currentAge = app.PointAges(i);
                
                if currentAge > 0
                    if currentAge >= MAX_BUFFER
                        app.PointAges(i) = 0; 
                        continue;
                    end
                    
                    % Sample Temperature
                    pX = max(1, min(maxCols, round(app.DroppedPointsX(i))));
                    pY = max(1, min(maxRows, round(app.DroppedPointsY(i))));
                    
                    % Grab the raw sampled value from the carved image
                    sampledTemp = FilteredImageCarved(pY, pX);
                    
                    % If the pixel value equals your maeakssk baseline (e.g., 25°C room temp),
                    % it means the point is currently obstructed by the nozzle or background.
                    % Force it to NaN so your downstream 'fillmissing' script knows to interpolate it!
                    if sampledTemp <= 40
                        app.TempMatrix(i, currentAge) = NaN;
                    else
                        app.TempMatrix(i, currentAge) = sampledTemp;
                    end
                    
                    % Log timestamp for the temperature reading
                    app.TimeMatrix(i, currentAge) = currentTime - app.BirthTimes(i);
                    
                    % ---> THE GRADUATION TRIGGER <---
                    if currentAge >= app.GradAge
                        
                        app.GradIndex = app.GradIndex + 1;
                        if app.GradIndex > MAX_BUFFER
                            app.GradIndex = 1;
                        end
                        
                        % Paste into Grad Matrices
                        n = app.GradAge;
                        app.GradTempMatrix(app.GradIndex, 1:n) = app.TempMatrix(i, 1:n);
                        app.GradTimeMatrix(app.GradIndex, 1:n) = app.TimeMatrix(i, 1:n);

                        % Cut from Aging Matrices
                        app.TempMatrix(i, :) = NaN;
                        app.TimeMatrix(i, :) = NaN;
                        app.PointAges(i) = 0;
                        
                    else
                        app.PointAges(i) = currentAge + 1;
                    end
                end
            end
        end

        function trackManualPoint(app, inputImage)
            % --- MANUAL THERMAL POINT TRACKING HELPER ---
            
            % Early exit if tracking is disabled to save CPU cycles
            if ~app.trackPointTemp    
                return;
            end
        
            % 1. Parse ROI Box dimensions and compute center offset
            boxSize = str2double(app.ROISizeDropDown.Value);
            offset = floor(boxSize / 2);
            
            cY = app.Y.Value;
            cX = app.X.Value;
            
            % 2. Establish and clamp coordinate boundaries to prevent array overflows
            [maxRows, maxCols] = size(inputImage);
            rowStart = max(1, cY - offset);
            rowEnd   = min(maxRows, cY + offset);
            colStart = max(1, cX - offset);
            colEnd   = min(maxCols, cX + offset);
            
            % 3. Synchronize spatial positions of UI overlay markers
            roiPositionVector = [colStart, rowStart, boxSize, boxSize];
            
            app.LiveFeedROIBox.Position = roiPositionVector;
            app.LiveFeedROIBox.Visible = 'on'; 
            
            app.FilteredROIBox.Position = roiPositionVector;
            app.FilteredROIBox.Visible = 'on'; 
        
            % 4. Extract localized pixel neighborhood and compute mean scalar temperature
            roiArray = inputImage(rowStart:rowEnd, colStart:colEnd);
            currentTemp = double(mean(roiArray, 'all'));
            
            % Calculate temperature delta relative to calibrated background temperature
            deltaT = currentTemp - app.EBTBGTemp.Value; 
        
            % 5. Record timestamp and append row to history: [Time, Temp, DeltaT]
            elapsedTime = seconds(datetime('now') - app.startTime);
            app.currentTempArray(end+1, :) = [elapsedTime, currentTemp, deltaT];
            
            % 6. Render live data point to the HMI strip-chart and digital gauge
            addpoints(app.pointLine, elapsedTime, currentTemp);
            app.CurrentTemp.Value = currentTemp;
        end
    
        function UpdateTemplatePreview(app)
            % Check if a template actually exists in memory
            if isempty(app.NozzleTemplate)
                % If no template exists, clear the axes
                cla(app.TemplatePreviewAxes);
                title(app.TemplatePreviewAxes, 'No Template Saved', 'Color', 'w');
            else
                % If it exists, display it using imagesc
                imagesc(app.TemplatePreviewAxes, app.NozzleTemplate);
                
                % Apply the same thermal color map you use for the live feed
                colormap(app.TemplatePreviewAxes, 'jet');
                
                % Force the axes to maintain the true aspect ratio of the rectangle
                axis(app.TemplatePreviewAxes, 'image'); 
                
                % Remove the title if it was previously set to "No Template"
                title(app.TemplatePreviewAxes, '');
            end
        end
    end
end