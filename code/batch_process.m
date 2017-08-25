%% batch process the VUMC results from the Hamburg MRF workshop

%% clean slate
close all; clear all; clc;

%% folder locations
folder_data_input  = '../data_input/';
folder_data_output = '../data_output/';
folder_png = '../png/';

%% detect list of .mat files to process
VUMC_MRF_images_files = dir(sprintf('%s/VUMC_MRF_*_images.mat', folder_data_input) );
nfile = numel(VUMC_MRF_images_files);

%% colormap for maps
cmap = jet; % match Philips Hamburg results summary

%% font size for maps and plots
font_size = 14;

%% loop over mat files
for idx_file = 1:nfile,
    
    %% assign filename and shortened prefix
    filename_images = VUMC_MRF_images_files(idx_file).name;
    filename_prefix = filename_images(1:end-11);
    
    %% load images
    % loads imgs
    % loads dictionary_name
    load( sprintf('%s/%s', folder_data_input, filename_images) );
    
    %% load dictionary
    % loads output_dict
    load( sprintf('%s/%s', folder_data_input, dictionary_name) );

    %% setup and call MRF_dict_match
    input_MRF_dict_match = [];
    input_MRF_dict_match.img_AR_comb = imgs;
    
    %% Jiang 1000 scan had alternating RF phase that was removed when converting from LAB/RAW/SIN
    % so put the 180 phase alternation back in!
    if size(imgs,3)==1000,
        input_MRF_dict_match.img_AR_comb(:,:,2:2:1000) = input_MRF_dict_match.img_AR_comb(:,:,2:2:1000) * exp(-1i*pi);
    end
    
    input_MRF_dict_match.reduce = 1; % use SVD acceleration
    output_MRF_dict_match = MRF_dict_match(input_MRF_dict_match, output_dict);
    
    %% assign maps
    T1_map = output_MRF_dict_match.T1_map;
    T2_map = output_MRF_dict_match.T2_map;
    M0_map = abs(output_MRF_dict_match.M0_map);
    R_map  = abs(output_MRF_dict_match.R_map);
    
    %% save maps to mat file
    filename_save = sprintf('%s/%s_maps.mat', folder_data_output, filename_prefix );
    disp( sprintf('Saving %02d of %02d: %s', idx_file, nfile, filename_save) );
    save(filename_save, 'T1_map', 'T2_map', 'R_map', 'M0_map', 'filename_prefix', 'dictionary_name');
    
end

%% create ROI masks
ROI_center_x = [111  83  67 71 92 122 150 166 163 142 135  94 98 139];
ROI_center_y = [164 152 125 93 71  64  76 103 134 157 136 132 92  95];
ROI_diameter = 7;
nROI = numel(ROI_center_x);
effMtx = 240;
[y_coords_2D, x_coords_2D] = meshgrid(1:effMtx);

ROI_masks = logical( zeros([effMtx effMtx nROI]) );

for idx_ROI = 1:nROI,
    this_ROI_mask = logical( zeros([effMtx effMtx]) );
    this_centered_radius_2D = sqrt( ( x_coords_2D - ROI_center_x(idx_ROI) ).^2 + ( y_coords_2D - ROI_center_y(idx_ROI) ).^2 );
    this_ROI_mask( this_centered_radius_2D<=ROI_diameter ) = true;
    ROI_masks(:,:,idx_ROI) = this_ROI_mask;
end

%% Known values
T1_known_ms_v = [2480 2173 1907 1604 1332 1044 801.7 608.6 458.4 336.5 244.2 176.6 126.9 90.9];
T2_known_ms_v = [581.3 403.5 278.1 190.94 133.27 96.89 64.07 46.42 31.97 22.56 15.813 11.237 7.911 5.592];

%% Create ROI matrices
T1_matrix_mean = zeros([nfile nROI]);
T2_matrix_mean = zeros([nfile nROI]);
R_matrix_mean = zeros([nfile nROI]);
M0_matrix_mean = zeros([nfile nROI]);
T1_matrix_sigma = zeros([nfile nROI]);
T2_matrix_sigma = zeros([nfile nROI]);
R_matrix_sigma = zeros([nfile nROI]);
M0_matrix_sigma = zeros([nfile nROI]);

%% concordance correlation coefficient (ccc) vectors
T1_ccc = zeros(nfile);
T2_ccc = zeros(nfile);
T2_zoom_ccc = zeros(nfile);
T2_zoom_max = 150;
idx_T2_zoom = find(T2_known_ms_v<=T2_zoom_max);

%% loop over map mat files
for idx_file = 1:nfile,
    
    %% assign filename and shortened prefix
    filename_images = VUMC_MRF_images_files(idx_file).name;
    filename_prefix = filename_images(1:end-11);
    filename_map = sprintf('%s/%s_maps.mat', folder_data_output, filename_prefix );
    
    %% load maps
    load(filename_map);

    %% loop over ROIs
    for idx_ROI = 1:nROI,
        this_ROI_mask = ROI_masks(:,:,idx_ROI);
        T1_values = T1_map( this_ROI_mask );
        T2_values = T2_map( this_ROI_mask );
        R_values = R_map( this_ROI_mask );
        M0_values = M0_map( this_ROI_mask );
        
        % mean values
        T1_matrix_mean(idx_file, idx_ROI) = mean( T1_values );
        T2_matrix_mean(idx_file, idx_ROI) = mean( T2_values );
        R_matrix_mean(idx_file, idx_ROI)  = mean( R_values );
        M0_matrix_mean(idx_file, idx_ROI) = mean( M0_values );
        
        % standard deviations (sigmas)
        T1_matrix_sigma(idx_file, idx_ROI) = std( T1_values );
        T2_matrix_sigma(idx_file, idx_ROI) = std( T2_values );
        R_matrix_sigma(idx_file, idx_ROI)  = std( R_values );
        M0_matrix_sigma(idx_file, idx_ROI) = std( M0_values );
    end
    
    %% concordance correlation coefficients
    T1_ccc(idx_file) = ccc(T1_known_ms_v, T1_matrix_mean(idx_file,:));
    T2_ccc(idx_file) = ccc(T2_known_ms_v, T2_matrix_mean(idx_file,:));
    T2_zoom_ccc(idx_file) = ccc(T2_known_ms_v(idx_T2_zoom), T2_matrix_mean(idx_file,idx_T2_zoom));
    
end

%% display and save plots to png file
T1_plot_max = 2700;
T2_plot_max = 700;
R_plot_max = 1.05;
for idx_file = 1:nfile,
    
    %% assign filename and shortened prefix
    filename_images = VUMC_MRF_images_files(idx_file).name;
    filename_prefix = filename_images(1:end-11);
    
    %% plot versus known values
    figure(2); clf; set(gcf,'Position',[150 150 2000 320],'Color',[1 1 1]);
    
    % T1
    subplot(1,5,1);
    plot([0 T1_plot_max],[0 T1_plot_max],'b-');
    hold on;
    errorbar(T1_known_ms_v, T1_matrix_mean(idx_file,:), T1_matrix_sigma(idx_file,:), 'r.' );
    set(gca, 'FontSize', font_size);
    axis square; grid on;
    xlabel('T1 (ms) - Truth'); ylabel('T1 (ms) - Measured'); title(filename_prefix,'Interpreter','none');
    axis([0 T1_plot_max 0 T1_plot_max]);
    text(0.5*T1_plot_max, 0.1*T1_plot_max, sprintf('CCC = %.4f', T1_ccc(idx_file) ), 'FontSize', font_size );
    
    % T2
    subplot(1,5,2);
    plot([0 T2_plot_max],[0 T2_plot_max],'b-');
    hold on;
    errorbar(T2_known_ms_v, T2_matrix_mean(idx_file,:), T2_matrix_sigma(idx_file,:), 'r.' );
    set(gca, 'FontSize', font_size);
    axis square; grid on;
    xlabel('T2 (ms) - Truth'); ylabel('T2 (ms) - Measured'); 
    axis([0 T2_plot_max 0 T2_plot_max]);  
    text(0.5*T2_plot_max, 0.1*T2_plot_max, sprintf('CCC = %.4f', T2_ccc(idx_file) ), 'FontSize', font_size );
    
	% T2 (zoom)
    subplot(1,5,3);
    plot([0 T2_plot_max],[0 T2_plot_max],'b-');
    hold on;
    errorbar(T2_known_ms_v, T2_matrix_mean(idx_file,:), T2_matrix_sigma(idx_file,:), 'r.' );
    set(gca, 'FontSize', font_size);
    axis square; grid on;
    xlabel('T2 (ms) - Truth (zoomed)'); ylabel('T2 (ms) - Measured (zoomed)'); 
    axis([0 T2_zoom_max 0 T2_zoom_max]);   
    text(0.5*T2_zoom_max, 0.1*T2_zoom_max, sprintf('CCC = %.4f', T2_zoom_ccc(idx_file) ), 'FontSize', font_size );
    
	% M0
    subplot(1,5,4);
    errorbar([1:nROI], M0_matrix_mean(idx_file,:), M0_matrix_sigma(idx_file,:), 'r.' );
    set(gca, 'FontSize', font_size);
    axis square; grid on;
    xlabel('ROI'); ylabel('M0 (a.u.)');
       
    % R
    subplot(1,5,5);
    errorbar([1:nROI], R_matrix_mean(idx_file,:), R_matrix_sigma(idx_file,:), 'r.' );
    set(gca, 'FontSize', font_size);
    axis square; grid on; xlabel('ROI'); ylabel('R (dictionary match normalized inner product)');
    axis([0 nROI+1 0 R_plot_max]);      
 
	%% save plots to png file
    filename_png = sprintf('%s/plots_%s.png', folder_png, filename_prefix );
    cdata = frame2im(getframe(figure(2)));
    imwrite(cdata,filename_png);
    
end

%% display and save maps to png file
for idx_file = 1:nfile,
    
    %% assign filename and shortened prefix
    filename_images = VUMC_MRF_images_files(idx_file).name;
    filename_prefix = filename_images(1:end-11);
    filename_map = sprintf('%s/%s_maps.mat', folder_data_output, filename_prefix );
    
    %% load maps
    load(filename_map);

    %% display results
    % flip and rotate to match orientation of Hamburg results
    figure(1); clf; set(gcf,'Position',[150 150 1800 320],'Color',[1 1 1]);
    
    subplot(1,4,1); imagesc( rot90(flipud(T1_map),+1), [0 3000]);
    set(gca, 'FontSize', font_size, 'Xtick', [], 'Ytick', []);
    axis image; colormap(cmap); colorbar;
    title(filename_prefix,'Interpreter','none');
    xlabel('T1 (ms)'); 
    
    subplot(1,4,2); imagesc( rot90(flipud(T2_map),+1), [0 2000]);
    set(gca, 'FontSize', font_size, 'Xtick', [], 'Ytick', []);
    axis image; colormap(cmap); colorbar; 
    xlabel('T2 (ms)');
    
    subplot(1,4,3); imagesc( rot90(flipud(M0_map),+1));
    set(gca, 'FontSize', font_size, 'Xtick', [], 'Ytick', []);
    axis image; colormap(cmap); colorbar;
    xlabel('M0 (a.u.)');
    
    subplot(1,4,4); imagesc( rot90(flipud(R_map),+1), [0 1.0]);
    set(gca, 'FontSize', font_size, 'Xtick', [], 'Ytick', []);
    axis image; colormap(cmap); colorbar; 
    xlabel('R (dictionary match normalized inner product)');
    
	%% save maps to png file
    filename_png = sprintf('%s/maps_%s.png', folder_png, filename_prefix );
    cdata = frame2im(getframe(figure(1)));
    imwrite(cdata,filename_png);

end

%% print markdown files for maps and plots
fid_maps_md = fopen(sprintf('%s/maps.md', folder_png), 'w');
fid_plots_md = fopen(sprintf('%s/plots.md', folder_png), 'w');
for idx_file=1:nfile,

    %% assign filename and shortened prefix
    filename_images = VUMC_MRF_images_files(idx_file).name;
    filename_prefix = filename_images(1:end-11);
    
    %% print to markdown
    fprintf(fid_maps_md,'![%s](maps_%s.png)\n', filename_prefix, filename_prefix);
    fprintf(fid_plots_md,'![%s](plots_%s.png)\n', filename_prefix, filename_prefix);
end
fclose(fid_maps_md);
fclose(fid_plots_md);

%% print markdown and csv files for ROI values
input = [];
for idx_file = 1:nfile,
    %% assign filename and shortened prefix
    filename_images = VUMC_MRF_images_files(idx_file).name;
    filename_prefix = filename_images(1:end-11);
    input.source_names{idx_file} = filename_prefix;
end

% T1 mean
input.prefix = '../tables/ROI_values_T1_mean';
input.truth = T1_known_ms_v;
input.ROI_values = T1_matrix_mean;
print_ROI_values_to_markdown_and_csv(input);

% T2 mean
input.prefix = '../tables/ROI_values_T2_mean';
input.truth = T2_known_ms_v;
input.ROI_values = T2_matrix_mean;
print_ROI_values_to_markdown_and_csv(input);

% T1 sigma
input.prefix = '../tables/ROI_values_T1_sigma';
input.truth = zeros(1,nROI);
input.ROI_values = T1_matrix_sigma;
print_ROI_values_to_markdown_and_csv(input);

% T2 sigma
input.prefix = '../tables/ROI_values_T2_sigma';
input.truth = zeros(1,nROI);
input.ROI_values = T2_matrix_sigma;
print_ROI_values_to_markdown_and_csv(input);