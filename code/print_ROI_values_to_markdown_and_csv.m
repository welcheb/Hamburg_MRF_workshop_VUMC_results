%% print ROI values to markdown and csv
%
% input.prefix       : string prefix for the written files
% input.source_names : cell array of the source names (nfile in length)
% input.truth        : vector of truth values (nROI in length)
% input.ROI_values   : matrix of ROI values (nfile by nROI)
%
function print_ROI_values_to_markdown_and_csv(input)

%% detect sizes
[nfile nROI] = size(input.ROI_values);

%% print markdown files for maps and plots
fid_md = fopen(sprintf('%s.md', input.prefix), 'w');
fid_csv = fopen(sprintf('%s.csv', input.prefix), 'w');

%% header row csv
fprintf(fid_csv,'source_name');
for idx_ROI = 1:nROI,
    fprintf(fid_csv,',ROI_%02d', idx_ROI);
end
fprintf(fid_csv,'\n');

%% header row markdown
fprintf(fid_md,'|  source_name  |');
for idx_ROI = 1:nROI,
    fprintf(fid_md,'  ROI_%02d  |', idx_ROI);
end
fprintf(fid_md,'\n');    
fprintf(fid_md,'|---------------|');
for idx_ROI = 1:nROI,
    fprintf(fid_md,'------------|', idx_ROI);
end
fprintf(fid_md,'\n');

%% truth row
fprintf(fid_csv,'TRUTH');
fprintf(fid_md,'|  TRUTH  |');
for idx_ROI = 1:nROI,
    fprintf(fid_csv,',%.4f', input.truth(idx_ROI) );
    fprintf(fid_md,'  %.4f  |', input.truth(idx_ROI) );
end
fprintf(fid_csv,'\n');
fprintf(fid_md,'\n');

%% ROI value rows
for idx_file = 1:nfile,
    fprintf(fid_csv, '%s', input.source_names{idx_file});
    fprintf(fid_md,'|  %s  |',  input.source_names{idx_file});
    for idx_ROI = 1:nROI,
        fprintf(fid_csv,',%.4f', input.ROI_values(idx_file, idx_ROI) );
        fprintf(fid_md,'  %.4f  |', input.ROI_values(idx_file, idx_ROI) );
    end
    fprintf(fid_csv,'\n');
    fprintf(fid_md,'\n');
end

%% close files
fclose(fid_md);
fclose(fid_csv);