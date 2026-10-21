% 1. Load the data
data = readmatrix('TempData.csv');

% 2. Create the heatmap
h = heatmap(data);

% 3. Style it for thermal data
h.Colormap = hot; % Standard thermal colors (black-red-yellow-white)
h.Title = 'Layer Temperature Distribution';
h.XLabel = 'Pixel X';
h.YLabel = 'Pixel Y';

% 4. Remove grid lines for a cleaner "image" look
grid off